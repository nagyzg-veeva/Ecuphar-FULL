// This class is based on https://github.com/andene/js-ioc-container.git 
export default class Container {

    static INSTANCE = new Container();
    constructor() {
        this._services = new Map();
        this._singletons = new Map();
    }

    register(name, definition, dependencies) {
        this._services.set(name, { definition: definition, dependencies: dependencies });
    }

    singleton(name, definition, dependencies) {
        this._services.set(name, { definition: definition, dependencies: dependencies, singleton: true });
    }

    get(name, fallback) {
        let c = this._services.get(name);
        if (!c && fallback) {
            c = this._services.get(fallback);
        }
        if (!c) {
            return undefined;
        }
        if (this._isClass(c.definition)) {
            if (c.singleton) {
                const singletonInstance = this._singletons.get(name);
                if (singletonInstance) {
                    return singletonInstance;
                }
                const newSingletonInstance = this._createInstance(c);
                this._singletons.set(name, newSingletonInstance);
                return newSingletonInstance;
            }
            return this._createInstance(c);
        }
        return c.definition;
    }

    _getResolvedDependencies(service) {
        let classDependencies = [];
        if (service.dependencies) {
            classDependencies = service.dependencies.map((dep) => {
                return this.get(dep);
            })
        }
        return classDependencies;
    }

    _createInstance(service) {
        return new service.definition(...this._getResolvedDependencies(service));
    }

    _isClass(definition) {
        return typeof definition === 'function';
    }
}