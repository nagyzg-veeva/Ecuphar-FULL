export default class AccountPlanHierarchy {

    constructor(childObjectName, parentRelationship, childRelationship) {
        this._childObjectName = childObjectName;
        this._parentRelationship = parentRelationship;
        this._childRelationship = childRelationship;
    }

    get childObjectName(){
        return this._childObjectName;
    }

    set childObjectName(value){
        this._childObjectName = value;
    }

    get parentRelationship(){
        return this._parentRelationship;
    }

    set parentRelationship(value){
        this._parentRelationship = value;
    }

    get childRelationship(){
        return this._childRelationship;
    }

    set childRelationship(value){
        this._childRelationship = value;
    }
}