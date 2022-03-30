(function() {
    var subTextColor = "#636363";

    function loadTemplates() {
        createAffiliationTemplate();
        createNodeTemplates();
    }

    function createAffiliationTemplate() {

        var green = "#14d411";
        var blue = '#0206f1';
        var red = '#ff3d0d';
        var gray = '#828282';
        OrgChart.clinkTemplates.noInf = Object.assign({}, OrgChart.clinkTemplates.blue);
        OrgChart.clinkTemplates.noInf.defs = '<marker id="noInf3end" viewBox="0 0 10 10" refX="8" refY="5" markerWidth="6" markerHeight="6" orient="auto-start-reverse"></marker><marker id="noInf3dot" viewBox="0 0 10 10" refX="5" refY="5" markerWidth="5" markerHeight="5"></marker>';
        OrgChart.clinkTemplates.noInf.link = '<path marker-start="url(#noInf3dot)" marker-end="url(#noInf3end)" stroke="' + gray + '" stroke-dasharray="15 4" stroke-width="2" fill="none" d="{d}" />'
        
        OrgChart.clinkTemplates.inf = Object.assign({}, OrgChart.clinkTemplates.blue);
        OrgChart.clinkTemplates.inf.defs = '<marker id="inf3arrow" viewBox="0 0 10 10" refX="8" refY="5" markerWidth="6" markerHeight="6" orient="auto-start-reverse"><path fill="' + gray + '" d="M 0 0 L 10 5 L 0 10 z" /></marker><marker id="inf3dot" viewBox="0 0 10 10" refX="5" refY="5" markerWidth="5" markerHeight="5"></marker>';
        OrgChart.clinkTemplates.inf.link = '<path marker-start="url(#inf3dot)" marker-end="url(#inf3arrow)" stroke="' + gray + '" stroke-width="2" fill="none" d="{d}" />'
        
        
        OrgChart.clinkTemplates.noInf2 = Object.assign({}, OrgChart.clinkTemplates.blue);
        OrgChart.clinkTemplates.noInf2.defs = '<marker id="noInf2end" viewBox="0 0 10 10" refX="8" refY="5" markerWidth="6" markerHeight="6" orient="auto-start-reverse"></marker><marker id="noInf2dot" viewBox="0 0 10 10" refX="5" refY="5" markerWidth="5" markerHeight="5"></marker>';
        OrgChart.clinkTemplates.noInf2.link = '<path marker-start="url(#noInf2dot)" marker-end="url(#noInf2end)" stroke="' + blue + '" stroke-dasharray="15 4" stroke-width="2" fill="none" d="{d}" />'
        
        OrgChart.clinkTemplates.inf2 = Object.assign({}, OrgChart.clinkTemplates.blue);
        OrgChart.clinkTemplates.inf2.defs = '<marker id="inf2arrow" viewBox="0 0 10 10" refX="8" refY="5" markerWidth="6" markerHeight="6" orient="auto-start-reverse"><path fill="' + blue + '" d="M 0 0 L 10 5 L 0 10 z" /></marker><marker id="inf2dot" viewBox="0 0 10 10" refX="5" refY="5" markerWidth="5" markerHeight="5"></marker>';
        OrgChart.clinkTemplates.inf2.link = '<path marker-start="url(#inf2dot)" marker-end="url(#inf2arrow)" stroke="' + blue + '" stroke-width="2" fill="none" d="{d}" />'
    
        
        OrgChart.clinkTemplates.noInf1 = Object.assign({}, OrgChart.clinkTemplates.blue);
        OrgChart.clinkTemplates.noInf1.defs = '<marker id="end" viewBox="0 0 10 10" refX="8" refY="5" markerWidth="6" markerHeight="6" orient="auto-start-reverse"></marker><marker id="dot" viewBox="0 0 10 10" refX="5" refY="5" markerWidth="5" markerHeight="5"></marker>';
        OrgChart.clinkTemplates.noInf1.link = '<path marker-start="url(#dot)" marker-end="url(#end)" stroke="' + green + '" stroke-dasharray="15 4" stroke-width="2" fill="none" d="{d}" />'

        OrgChart.clinkTemplates.inf1 = Object.assign({}, OrgChart.clinkTemplates.blue);
        OrgChart.clinkTemplates.inf1.defs = '<marker id="noInf1arrow" viewBox="0 0 10 10" refX="8" refY="5" markerWidth="6" markerHeight="6" orient="auto-start-reverse"><path fill="' + green + '" d="M 0 0 L 10 5 L 0 10 z" /></marker><marker id="noInf1dot" viewBox="0 0 10 10" refX="5" refY="5" markerWidth="5" markerHeight="5"></marker>';
        OrgChart.clinkTemplates.inf1.link = '<path marker-start="url(#noInf1dot)" marker-end="url(#noInf1arrow)" stroke="' + green + '" stroke-width="2" fill="none" d="{d}" />'

        
        OrgChart.clinkTemplates.noInf0 = Object.assign({}, OrgChart.clinkTemplates.blue);
        OrgChart.clinkTemplates.noInf0.defs = '<marker id="noInf0end" viewBox="0 0 10 10" refX="8" refY="5" markerWidth="6" markerHeight="6" orient="auto-start-reverse"></marker><marker id="noInf0dot" viewBox="0 0 10 10" refX="5" refY="5" markerWidth="5" markerHeight="5"></marker>';
        OrgChart.clinkTemplates.noInf0.link = '<path marker-start="url(#noInf0dot)" marker-end="url(#noInf0end)" stroke="' + red + '" stroke-dasharray="15 4" stroke-width="2" fill="none" d="{d}" />'

        OrgChart.clinkTemplates.inf0 = Object.assign({}, OrgChart.clinkTemplates.blue);
        OrgChart.clinkTemplates.inf0.defs = '<marker id="inf0arrow" viewBox="0 0 10 10" refX="8" refY="5" markerWidth="6" markerHeight="6" orient="auto-start-reverse"><path fill="' + red + '" d="M 0 0 L 10 5 L 0 10 z" /></marker><marker id="inf0dot" viewBox="0 0 10 10" refX="5" refY="5" markerWidth="5" markerHeight="5"></marker>';
        OrgChart.clinkTemplates.inf0.link = '<path marker-start="url(#inf0dot)" marker-end="url(#inf0arrow)" stroke="' + red + '" stroke-width="2" fill="none" d="{d}" />'

        OrgChart.clinkTemplates.default = Object.assign({}, OrgChart.clinkTemplates.blue);
        OrgChart.clinkTemplates.default.defs = '<marker id="defaultend" viewBox="0 0 10 10" refX="8" refY="5" markerWidth="6" markerHeight="6" orient="auto-start-reverse"></marker><marker id="defaultdot" viewBox="0 0 10 10" refX="5" refY="5" markerWidth="5" markerHeight="5"></marker>';
        OrgChart.clinkTemplates.default.link = '<path marker-start="url(#defaultdot)" marker-end="url(#defaultend)" stroke="' + gray + '" stroke-dasharray="15 4" stroke-width="2" fill="none" d="{d}" />'
    }

    function createNodeTemplates() { 
        setGeneralTemplates();
        createBaseTemplate();
        createAffOnlyBaseTemplate();
        createChildOnlyBaseTemplate();
        createAffAndChildBaseTemplate();
        createUnloadedChildrenTemplate(OrgChart.templates.baseNode, "unloadedChildrenAffOnly", true);
        createUnloadedChildrenTemplate(OrgChart.templates.baseNode, "unloadedChildrenNoAff", false);
        createExpandCollapseNodeTemplate(OrgChart.templates.childOnlyBase, "expandCollapseChildOnly");
        createExpandCollapseNodeTemplate(OrgChart.templates.bothBase, "expandCollapseBoth");
        createLoadingTemplate();
        createLoadMoreTemplate();
        createLoadParentTemplate();
    }

    function setGeneralTemplates() {
        OrgChart.MIXED_LAYOUT_ALL_NODES = false;
        
        OrgChart.templates.split.link = `<path stroke="#000000" stroke-width="2px" fill="none" d="M{xa},{ya} {xb},{yb} {xc},{yc} L{xd},{yd}"/>`;
        OrgChart.templates.split.node = `<circle cx="5" cy="5" r="4" stroke="black" stroke-width="3" fill="black" />`;
    }

    function createBaseTemplate() {
        OrgChart.templates.baseNode = Object.assign({}, OrgChart.templates.ula);
        OrgChart.templates.baseNode.size = [300, 110];
        OrgChart.templates.baseNode.link = '<path stroke="#000000" stroke-width="2px" fill="none" d="M{xa},{ya} {xb},{yb} {xc},{yc} L{xd},{yd}"/>';
        OrgChart.templates.baseNode.node = `<rect class=main-node rx="6" ry="6" x="0" y="0" height="{h}" width="{w}" fill="#ffffff"></rect>`;
        OrgChart.templates.baseNode.field_0 = `<text width="200" style="font-size: 16px; font-weight: bold;" fill="#000000" x="90" y="35">{val}</text>`;
        OrgChart.templates.baseNode.field_1 = '<text width="200" style="font-size: 14px;" fill="' + subTextColor + '" x="90" y="56">{val}</text>';
        OrgChart.templates.baseNode.img_0 = `<image preserveAspectRatio="xMidYMid slice" xlink:href="{val}" x="10" y="20" width="70" height="70" ></image>`
        OrgChart.templates.baseNode.nodeMenuButton = `
            <g style="cursor:pointer;" transform="matrix(1,0,0,1,275,7)" control-node-menu-id="{id}">
                <rect x="-4" y="-10" fill="#000000" fill-opacity="0" width="22" height="22"></rect>
                <line x1="0" y1="3" x2="16" y2="3" stroke-width="2" stroke="#636363"></line>
                <line x1="0" y1="8" x2="16" y2="8" stroke-width="2" stroke="#636363"></line>
                <line x1="0" y1="13" x2="16" y2="13" stroke-width="2" stroke="#636363"></line>
            </g>`
        OrgChart.templates.baseNode.defs = `
            <filter x="-50%" y="-50%" width="200%" height="200%" filterUnits="objectBoundingBox" id="sn-drop-shadow">
                <feOffset dx="0" dy="4" in="SourceAlpha" result="shadowOffsetOuter1" />
                <feGaussianBlur stdDeviation="10" in="shadowOffsetOuter1" result="shadowBlurOuter1" />
                <feColorMatrix values="0 0 0 0 0   0 0 0 0 0   0 0 0 0 0  0 0 0 0.2 0" in="shadowBlurOuter1" type="matrix" result="shadowMatrixOuter1" />
                <feMerge>
                    <feMergeNode in="shadowMatrixOuter1" />
                    <feMergeNode in="SourceGraphic" />
                </feMerge>
            </filter>`;
        OrgChart.templates.baseNode.plus = '';
        OrgChart.templates.baseNode.minus = '';
        OrgChart.templates.baseNode.numChild = '';
        OrgChart.templates.baseNode.numAff = '';
    }

    function createAffOnlyBaseTemplate() {
        OrgChart.templates.affOnlyBase = Object.assign({}, OrgChart.templates.baseNode);
        OrgChart.templates.affOnlyBase.numAff = '<polygon class="affIcon" points="285,85 290,93 280,93" fill="#c90000" stroke="#c90000" stroke-width="1"/><line class="affIcon" x1="285" y1="93" x2="285" y2="99" stroke-width="2" stroke="#c90000"/><text width="120" text-anchor="end" font-size="19px" fill="' + subTextColor + '" x="275" y="99">{val}</text>';
    }

    function createChildOnlyBaseTemplate() {
        OrgChart.templates.childOnlyBase = Object.assign({}, OrgChart.templates.baseNode);
        OrgChart.templates.childOnlyBase.numChild = '<path d="M279,100 a1.5,1 0 0 1 12,0" stroke="#123dff" fill="#123dff" stroke-width="2"/><circle cx="285" cy="89" r="4" stroke="#123dff" fill="#123dff" stroke-width="1"/><text width="120" text-anchor="end" font-size="19px" fill="' + subTextColor + '" x="275" y="100">{val}</text>';
    }

    function createAffAndChildBaseTemplate() {
        OrgChart.templates.bothBase = Object.assign({}, OrgChart.templates.baseNode);
        OrgChart.templates.bothBase.numAff = '<polygon class="affIcon" points="285,62 290,70 280,70" fill="#c90000" stroke="#c90000" stroke-width="1"/><line class="affIcon" x1="285" y1="70" x2="285" y2="76" stroke-width="2" stroke="#c90000"/><text width="120" text-anchor="end" font-size="19px" fill="' + subTextColor + '" x="275" y="76">{val}</text>';
        OrgChart.templates.bothBase.numChild = '<path d="M279,100 a1.5,1 0 0 1 12,0" stroke="#123dff" fill="#123dff" stroke-width="2"/><circle cx="285" cy="89" r="4" stroke="#123dff" fill="#123dff" stroke-width="1"/><text width="120" text-anchor="end" font-size="19px" fill="' + subTextColor + '" x="275" y="100">{val}</text>';
    }

    function createExpandCollapseNodeTemplate(baseTemplate, newTemplateName) {
        OrgChart.templates[newTemplateName] = Object.assign({}, baseTemplate);
        OrgChart.templates[newTemplateName].node += `
            <g class="expand-collapse-button">
                <circle class="expand" filter="url(#sn-drop-shadow)" cx="150" cy="102" r="20" fill="#ffffff" />
                <line class="expand" x1="150" y1="110" x2="150" y2="95" stroke="#000000" stroke-width="2" />
                <polyline class="expand" points="140,107 150,95 160,107" stroke="#000000" stroke-width="2" fill="transparent" />
                <circle class="collapse" filter="url(#sn-drop-shadow)" cx="150" cy="102" r="20" fill="#ffffff" />
                <line class="collapse" x1="150" y1="112" x2="150" y2="92" stroke="#000000" stroke-width="2" />
                <polyline class="collapse" points="140,102 150,112 160,102" stroke="#000000" stroke-width="2" fill="transparent" />
            </g>`;
    }

    function createUnloadedChildrenTemplate(baseTemplate, newTemplateName, hasAff) {
        OrgChart.templates[newTemplateName] = Object.assign({}, baseTemplate);
        OrgChart.templates[newTemplateName].node += `
            <g class="load-children-button">
                <circle filter="url(#sn-drop-shadow)" cx="150" cy="85" r="20" />
                <line x1="140" y1="85" x2="160" y2="85" stroke="#000000" stroke-width="2" />
                <line x1="150" y1="95" x2="150" y2="75" stroke="#000000" stroke-width="2" />
            </g>`;
        OrgChart.templates[newTemplateName].numChildId = '<path d="M279,100 a1.5,1 0 0 1 12,0" stroke="#123dff" fill="#123dff" stroke-width="2"/><circle cx="285" cy="89" r="4" stroke="#123dff" fill="#123dff" stroke-width="1"/><text width="120" text-anchor="end" font-size="19px" fill="' + subTextColor + '" x="275" y="100">{val}</text>';
        if (hasAff) {
            OrgChart.templates[newTemplateName].numAff = '<polygon class="affIcon" points="285,62 290,70 280,70" fill="#c90000" stroke="#c90000" stroke-width="1"/><line class="affIcon" x1="285" y1="70" x2="285" y2="76" stroke-width="2" stroke="#c90000"/><text width="120" text-anchor="end" font-size="19px" fill="' + subTextColor + '" x="275" y="76">{val}</text>';
        }
    }

    function createLoadingTemplate() {
        OrgChart.templates.loadingNode = Object.assign({}, OrgChart.templates.baseNode);
        OrgChart.templates.loadingNode.size = [100, 100];
        OrgChart.templates.loadingNode.node = `<rect x="0" y="0" height="{h}" width="{w}" fill="#ffffff" fill-opacity="0"></rect>`;
        OrgChart.templates.loadingNode.img_0 = `<image preserveAspectRatio="xMidYMid slice" clip-path="url(#sn-drop-shadow)" xlink:href="{val}" x="10" y="5" width="80" height="80" ></image>"`;
        OrgChart.templates.loadingNode.nodeMenuButton = ""
    }

    function createLoadMoreTemplate() {
        OrgChart.templates.loadMoreNode = Object.assign({}, OrgChart.templates.baseNode);
        OrgChart.templates.loadMoreNode.size = [100, 100];
        OrgChart.templates.loadMoreNode.node = `
            <circle class="base" filter="url(#sn-drop-shadow)" cx="50" cy="50" r="50" fill="#ffffff"></circle>
            <circle cx="30" cy="50" r="5" fill="#000000"></circle>
            <circle cx="50" cy="50" r="5" fill="#000000"></circle>
            <circle cx="70" cy="50" r="5" fill="#000000"></circle>`;
        OrgChart.templates.loadMoreNode.img_0 = "";
        OrgChart.templates.loadMoreNode.field_0 = "";
        OrgChart.templates.loadMoreNode.field_1 = "";
        OrgChart.templates.loadMoreNode.nodeMenuButton = ""
    }

    function createLoadParentTemplate() {
        OrgChart.templates.loadParentNode = Object.assign({}, OrgChart.templates.baseNode);
        OrgChart.templates.loadParentNode.size = [100, 100];
        OrgChart.templates.loadParentNode.node = `
            <circle filter="url(#sn-drop-shadow)" cx="50" cy="50" r="50" fill="#ffffff"></circle>
            <line x1="30" y1="50" x2="70" y2="50" stroke-width="4" stroke="#000000"></line>
            <line x1="50" y1="30" x2="50" y2="70" stroke-width="4" stroke="#000000"></line>`;
        OrgChart.templates.loadParentNode.img_0 = "";
        OrgChart.templates.loadParentNode.field_0 = "";
        OrgChart.templates.loadParentNode.field_1 = "";
        OrgChart.templates.loadParentNode.plus = "";
        OrgChart.templates.loadParentNode.minus = "";
        OrgChart.templates.loadParentNode.nodeMenuButton = "";
    }

    loadTemplates();
})();
