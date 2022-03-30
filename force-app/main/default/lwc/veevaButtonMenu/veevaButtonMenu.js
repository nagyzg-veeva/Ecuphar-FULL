import { LightningElement, api } from "lwc";

const BOTTOM_BUFFER = 10;

export default class VeevaButtonMenu extends LightningElement {
    // Menu alignment can either be left or right
    @api menuAlignment;
    showDropdown = false;
    _handler;
    @api title = "Down";


    disconnectedCallback() {
        document.removeEventListener("click", this._handler);
    }

    handleClick(event) {
        event.stopPropagation();
        this.showDropdown = !this.showDropdown;

        if (this.showDropdown) {
            // Create listener for clicks outside menu LWC
            document.addEventListener("click", (this._handler = this.closeDropdown.bind(this)));
            const button = this.template.childNodes[0];
            const dropdown = this.template.childNodes[0].childNodes[1];

            if (!this.menuAlignment) {
                dropdown.style.right = 'auto';
                const dropdownLeft = button.offsetLeft - dropdown.offsetWidth + button.offsetWidth;
                dropdown.style.left = `${dropdownLeft}px`;
            }

            if (button.offsetTop + button.offsetHeight + dropdown.offsetHeight + BOTTOM_BUFFER > window.innerHeight) {
                const dropdownTop = button.offsetTop - dropdown.offsetHeight-5;
                dropdown.style.top = `${dropdownTop}px`;
            }
        }
    }

    closeDropdown() {
        document.removeEventListener("click", this._handler);
        this.showDropdown = false;
    }

    get dropdownCss() {
        let alignment = "left";
        if (this.menuAlignment === "right") {
            alignment = this.menuAlignment;
        }
        // Instead of using if:true directive, using visibility CSS property
        // In order to hide parent menu, while keeping child modal open
        let hiddenClass = "hideMenu";
        if (this.showDropdown) {
            hiddenClass = "";
        }
        return `slds-dropdown slds-dropdown_actions slds-dropdown_${alignment} ${hiddenClass}`;
    }
}