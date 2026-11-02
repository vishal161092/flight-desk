import { LightningElement } from 'lwc';

export default class De_dummy_booking_summary extends LightningElement {
    flightRecords = [
        {
            id: '1',
            pnr: '5C4UPQ',
            ticketName: 'RAJ SHARMA',
            date: '16 Mar 2026',
            flightNo: 'ZA2018',
            route: 'LHR - DEL',
            cabinClass: 'Economy'            
        },
        {
            id: '2',
            pnr: '9F9UIP',
            ticketName: 'RAJ SHARMA',
            date: '10 Mar 2026',
            flightNo: 'ZA2017',
            route: 'DEL - LHR',
            cabinClass: 'Economy'            
        },
    ];
}