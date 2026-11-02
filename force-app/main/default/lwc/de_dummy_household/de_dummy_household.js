import { LightningElement, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

export default class De_dummy_household extends NavigationMixin(LightningElement) {
    @track spouse = {
        name: 'Sunita Sharma',
        role: 'Wife',
        age: '10/04/1984',
        occupation: 'Corporate',
        phone: '*****3794',
        income: 'Platinum'
    };

    @track dependents = [];

    handleNavigationClick() {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: 'a4EWt0000008LvJMAU',
                objectApiName: 'Household__c',
                actionName: 'view'
            },
        });
    }

    @track summary = {
        totalMembers: 2,
        totalDependents: 0,
        totalIncome: ''
    };

    // You can add more JavaScript logic here if needed,
    // for example, to fetch data from Apex or handle user interactions.
}