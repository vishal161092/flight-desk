import { LightningElement } from 'lwc';
import getLoyaltyDetails from "@salesforce/apex/DE_Upcoming_and_Past_Itineraries.getLoyaltyDetails";

export default class De_loyalty_card extends LightningElement {

    fname;
    lname;
    bluchipMembership;
    clubMembershipId;
    nameCheck = false;
    loadingSpinner = true;
    clubPoints;

    connectedCallback() {
    getLoyaltyDetails({
      // quoteId: this.quoteId
    })
      .then((result) => {
        console.log(">> " + JSON.stringify(result));
        this.loadingSpinner = false;
        this.fname = result.first_name__c;
        this.lname = result.last_name__c;
        this.clubMembershipId = 'ZC-000001';
        this.clubPoints = result.club_points__c;

        if(this.fname == 'Payal'){
          this.nameCheck = true;
        }

        this.loadingSpinner = false;
      })
      .catch((error) => {
        console.log("@@ " + error);
      });
  }
}