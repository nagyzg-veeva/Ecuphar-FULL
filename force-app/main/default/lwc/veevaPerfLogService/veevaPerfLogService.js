import { getPageController } from 'c/veevaPageControllerFactory';

const EPT_MARK_ENTRY = 'PageView EPT';
export default class VeevaPerfLogService {
  pageName;
  objectType;
  appName;
  dataService;
  eventList = {};
  ept = null;
  lwcRenderEvent = {};
  totalNumberOfResources = null;

  constructor() {
    this.dataService = getPageController('dataSvc');
  }

  logPagePerformance(pageName, objType, lwcRenderEventRef) {
    this.pageName = pageName;
    this.objectType = objType;
    this.appName = objType;
    if (objType && objType.toLowerCase().endsWith('_vod__c')) {
      this.appName = objType.substring(0, objType.indexOf('_vod__c'));
    }
    // Capture some Performance Information now since we will send the metrics when the browser has freed up
    // We check to see if we have already captured the pageViewStart time
    this.pageViewStart = !this.pageViewStart ? getViewStart() : this.pageViewStart;
    this.totalNumberOfResources = this.totalNumberOfResources ?? window.performance.getEntriesByType('resource').length;
    this.lwcRenderEvent = getLwcRenderEvent(lwcRenderEventRef);

    const logPerformanceCallback = () => {
      this.checkAndLogPerformance();
    };

    // Wait at most five seconds before logging performance.
    const timeoutTime = 5000;
    if ('requestIdleCallback' in window) {
      requestIdleCallback(logPerformanceCallback, { timeout: timeoutTime });
    } else {
      // eslint-disable-next-line @lwc/lwc/no-async-operation
      setTimeout(logPerformanceCallback, timeoutTime);
    }
  }

  checkAndLogPerformance() {
    this.ept = getEPT(this.pageViewStart);
    if (this.ept) {
      this._logPagePerformance();
    } else {
      // If we still do not have the EPT time measure we will wait some more time and call logPagePerformance again
      // eslint-disable-next-line @lwc/lwc/no-async-operation
      setTimeout(() => this.logPagePerformance(this.pageName, this.objectType, this.lwcRenderEvent), 250);
    }
  }

  _logPagePerformance() {
    this.initializeEvents();
    this.send();
  }

  performanceConfig = {
    domLoad: ['domComplete', 'navigationStart'],
    pageLoadTime: ['loadEventEnd', 'navigationStart'],
    ttfbTime: ['responseEnd', 'requestStart'], // TTFB
  };

  addEvent(_defaults) {
    const defaults = { ..._defaults };
    const appName = defaults.app;
    let existing = this.eventList[appName];
    const newEvent = {
      event: null,
      start: +new Date(),
      end: null,
      duration: null,
      aborted: false,
      ready: false,
    };

    if (!existing) {
      existing = {
        version: '1',
        app: appName,
        page: defaults.page,
        object: defaults.object,
        events: [],
      };
      this.eventList[appName] = existing;
    }

    delete defaults.app;
    delete defaults.page;
    delete defaults.object;

    Object.keys(defaults)
      .filter(key => defaults[key])
      .forEach(key => {
        newEvent[key] = defaults[key];
      });

    existing.events.push(newEvent);
    return newEvent;
  }

  initializeEvents() {
    Object.keys(this.performanceConfig)
      .filter(evName => this.performanceConfig[evName])
      .forEach(evName => {
        const parameters = {
          app: this.appName,
          page: this.pageName,
          event: evName,
          object: this.objectType,
          ready: true,
        };
        this.addEvent(parameters);
      });
  }

  send() {
    let readyEvents = [];
    const eventsToSend = [];
    let appEvent;
    let events;
    let event;
    const performance = window.performance.timing || {};
    Object.keys(this.eventList).forEach(appName => {
      if (this.eventList[appName]) {
        appEvent = this.eventList[appName];
        if (!appEvent || !appEvent.events || appEvent.events.length === 0) {
          return;
        }
        events = JSON.parse(JSON.stringify(appEvent.events));
        readyEvents = [];

        for (let i = 0; i < events.length; i++) {
          event = events[i];
          delete event.ready;
          const eventName = event.event;
          if (this.performanceConfig[eventName]) {
            event.start = performance[this.performanceConfig[eventName][1]];
            event.end = performance[this.performanceConfig[eventName][0]];
          }

          // If the event didn't have an end time
          // force it to now and mark as aborted
          if (!event.end) {
            event.end = +new Date();
            event.aborted = true;
          }

          event.duration = event.end - event.start;
          delete event.end;

          readyEvents.push(event);

          for (let k = 0; k < appEvent.events.length; k++) {
            if (appEvent.events[k].event === event.event) {
              appEvent.events.splice(k, 1);
              break;
            }
          }
        }
        if (readyEvents.length > 0) {
          try {
            if (window.performance) {
              // first contentful paint
              const firstContentFulPaintEntry = 'first-contentful-paint';
              const contentfulPaintEntries = window.performance.getEntriesByName(firstContentFulPaintEntry, 'paint');
              if (contentfulPaintEntries && contentfulPaintEntries.length > 0) {
                readyEvents.push({ event: firstContentFulPaintEntry, duration: contentfulPaintEntries[0].startTime });
              }

              // EPT
              if (this.ept) {
                readyEvents.push({ event: 'EPT', duration: this.ept.duration });
                this.ept = null;
              }

              // total # of request
              readyEvents.push({ event: 'Total Page Request Count', count: this.totalNumberOfResources });
            }

            if (window.navigator) {
              // user agent and device info
              const { userAgent } = window.navigator;
              readyEvents.push({ event: 'user Agent and Device Info', userAgent });
            }

            if (this.lwcRenderEvent) {
              const { lwcRenderStart, lwcRenderEnd } = this.lwcRenderEvent;
              const lwcRenderEventDuration = lwcRenderEnd - lwcRenderStart;
              readyEvents.push({
                event: 'lwcRenderTime',
                duration: lwcRenderEventDuration,
                start: lwcRenderStart,
              });
            }
          } catch (e) {
            // eslint-disable-next-line no-console
            console.log(e);
          }

          eventsToSend.push({
            version: appEvent.version,
            app: appEvent.app,
            page: appEvent.page,
            object: appEvent.object,
            events: readyEvents,
          });
        }
        if (appEvent.events.length === 0) {
          delete this.eventList.appName;
        }
      }
    });

    if (eventsToSend.length > 0) {
      for (let j = 0; j < eventsToSend.length; j++) {
        this.dataService.logClientPageTiming(eventsToSend[j]);
      }
    }
  }
}

function getLwcRenderEvent(lwcRenderEventRef) {
  const lwcRenderEvent = { ...lwcRenderEventRef };
  if (lwcRenderEvent && lwcRenderEvent.start && !lwcRenderEvent.lwcRenderEnd) {
    lwcRenderEvent.lwcRenderStart = lwcRenderEvent.start;
    lwcRenderEvent.lwcRenderEnd = +new Date();
  }
  return lwcRenderEvent;
}

function getViewStart() {
  const eptMarkEntries = window.performance.getEntriesByName('ltng:pageView', 'mark');
  if (eptMarkEntries && eptMarkEntries.length > 0) {
    return eptMarkEntries[eptMarkEntries.length - 1].startTime;
  }
  return 0;
}

function getEPT(startTime) {
  return window.performance.getEntriesByName(EPT_MARK_ENTRY, 'measure').find(entry => entry.startTime >= startTime);
}