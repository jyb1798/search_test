import { LightningElement, track } from 'lwc';
import getAccounts from '@salesforce/apex/accountController.getAccounts';
import getContacts from '@salesforce/apex/accountController.getContacts';

export default class Tpms extends LightningElement {
    key;
    @track accounts;
    @track contacts;

    updateKey(event){
        this.key = event.target.value;
    }

    handleSearch(){
        getAccounts({searchkey: this.key})
        .then(result=>{
            this.accounts = result;
        })
        .catch(error=>{
            this.accounts = null;
        });
        getContacts({searchkey: this.key})
        .then(result=>{
            this.contacts = result;
        })
        .catch(error=>{
            this.contact = null;
        });
    }


    // async handleSearch() {
    //     const searchKey = this.key;
    //     const [accounts, contacts] = await Promise.all([
    //       getAccounts({ searchKey }), getContacts({ searchKey })
    //     ])
    //     this.accounts = accounts;
    //     this.contacts = contacts;
    //   }


    cols=[
        {label: '규격번호', fieldName: 'Phone', type: 'phone'},
        {label: '규격명', fieldName: 'Name', type: 'text'},
        {label: '규격종류', fieldName: 'Industry', type: 'text'},
        {label: '작성일', fieldName: 'Phone', type: 'phone'},
        {label: '상태', fieldName: 'Industry', type: 'text'}
    ]

    colums=[
        {label: '규격서번호', fieldName: 'Phone', type: 'phone'},
        {label: '제품포장규격명', fieldName: 'Name', type: 'text'},
        {label: '생산처', fieldName: 'Email', type: 'text'},
        {label: '최종수정일', fieldName: 'Phone', type: 'phone'},
        {label: '상태', fieldName: 'Email', type: 'text'}
    ]

}