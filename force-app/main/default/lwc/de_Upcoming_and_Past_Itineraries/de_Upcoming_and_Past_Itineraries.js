import { LightningElement, api } from "lwc";
import { NavigationMixin } from "lightning/navigation";
import getItineraryDetails from "@salesforce/apex/DE_Upcoming_and_Past_Itineraries.getBookingDetails";

export default class De_Upcoming_and_Past_Itineraries extends NavigationMixin(
  LightningElement
) {
  @api Title = "Past & Future Itinerary";
  @api TitleColor = "#861629";

  @api cardHeadColor = "#861629";
  @api cardContentColor = "White";

  @api cardPrimaryTextColor = "White";
  @api cardSecondaryTextColor = "#C5A55A";

  @api contentLabelnClassTextColor = "#861629";
  @api contentPrimaryTextColor = "#333";
  @api contentSecondaryTextColor = "#333";

  @api buttonColor = "#C5A55A";
  @api buttonBackgroundColor = "rgba(197, 165, 90, 0.08)";

  itineraryDetails = [];
  loadingSpinner = true;

  connectedCallback() {
    getItineraryDetails({
      // quoteId: this.quoteId
    })
      .then((result) => {
        console.log(">> " + JSON.stringify(result));
        this.itineraryDetails = result;
        this.loadingSpinner = false;
      })
      .catch((error) => {
        console.log("@@ " + error);
      });
  }

  renderedCallback() {
    let titleColor = this.template.querySelector(".titleColor");
    titleColor.style.color = this.TitleColor;

    let cardPrimaryTextColor = this.template.querySelectorAll(
      ".cardPrimaryTextColor"
    );
    for (let i = 0; i < cardPrimaryTextColor.length; i++) {
      cardPrimaryTextColor[i].style.color = this.cardPrimaryTextColor;
    }

    let contentLabelnClassTextColor = this.template.querySelectorAll(
      ".contentLabelnClassTextColor"
    );
    for (let i = 0; i < contentLabelnClassTextColor.length; i++) {
      contentLabelnClassTextColor[i].style.color =
        this.contentLabelnClassTextColor;
    }

    let cardHeadColor = this.template.querySelectorAll(".backgroundHeadColor");
    for (let i = 0; i < cardHeadColor.length; i++) {
      cardHeadColor[i].style.backgroundColor = this.cardHeadColor;
    }

    let cardContentColor = this.template.querySelectorAll(
      ".backgroundContentColor"
    );
    for (let i = 0; i < cardContentColor.length; i++) {
      cardContentColor[i].style.backgroundColor = this.cardContentColor;
    }

    let cardSecondaryTextColor = this.template.querySelectorAll(
      ".cardSecondaryTextColor"
    );
    for (let i = 0; i < cardSecondaryTextColor.length; i++) {
      cardSecondaryTextColor[i].style.color = this.cardSecondaryTextColor;
    }

    let contentPrimaryTextColor = this.template.querySelectorAll(
      ".contentPrimaryTextColor"
    );
    for (let i = 0; i < contentPrimaryTextColor.length; i++) {
      contentPrimaryTextColor[i].style.color = this.contentPrimaryTextColor;
    }

    let contentSecondaryTextColor = this.template.querySelectorAll(
      ".contentSecondaryTextColor"
    );
    for (let i = 0; i < contentSecondaryTextColor.length; i++) {
      contentSecondaryTextColor[i].style.color = this.contentSecondaryTextColor;
    }

    let buttonColor = this.template.querySelectorAll(".buttonColor");
    for (let i = 0; i < buttonColor.length; i++) {
      buttonColor[i].style.color = this.buttonColor;
      buttonColor[i].style.background = this.buttonBackgroundColor;
    }
  }

  // openLink(event) {
  //   console.log(">>> " + event.target.dataset.targetId);

  //   this[NavigationMixin.Navigate]({
  //     type: "standard__recordPage",
  //     attributes: {
  //       recordId: event.target.dataset.targetId,
  //       objectApiName: "Custom_Itinerary__c",
  //       actionName: "view"
  //     }
  //   });
  // }
}