import { LightningElement, api } from 'lwc';

export default class De_fake_CI_Ent extends LightningElement {

    @api recordId;

    PTBValue;
    CLTV;
    npsVal;
    serviceNPS;
    

    connectedCallback() {

    const URLaddress = location.pathname;
        console.log('URLaddress>> '+URLaddress);
        if (URLaddress) {
            const match = URLaddress.match(/\/([a-zA-Z0-9]{18})[\/]?/);
            if (match) {
                this.recordId = match[1];
            }
            console.log('recordId>> '+this.recordId);
    }
    
    console.log('RecId > '+this.recordId);

        this.PTBValue = '85';
        this.CLTV = 'Excellent';
        this.npsVal = 'Low';
        this.serviceNPS = '92';
    
    }



}