/* eslint-disable */
import web3 from './web3';

const address = '0x740c8109a2A3c5B9f317DbBba93CbC6ae5c3686E';

const abi = 
[
	{
		"anonymous": false,
		"inputs": [
			{
				"indexed": false,
				"internalType": "address",
				"name": "coAddress",
				"type": "address"
			},
			{
				"indexed": false,
				"internalType": "address",
				"name": "ownerAdress",
				"type": "address"
			},
			{
				"indexed": false,
				"internalType": "uint256",
				"name": "deadline",
				"type": "uint256"
			},
			{
				"indexed": false,
				"internalType": "uint256",
				"name": "goalAmount",
				"type": "uint256"
			},
			{
				"indexed": false,
				"internalType": "string",
				"name": "campaignTitle",
				"type": "string"
			},
			{
				"indexed": false,
				"internalType": "string",
				"name": "campaignDesc",
				"type": "string"
			}
		],
		"name": "CampaignStarted",
		"type": "event"
	},
	{
		"constant": true,
		"inputs": [],
		"name": "returnAllCampaigns",
		"outputs": [
			{
				"internalType": "contract Campaign[]",
				"name": "",
				"type": "address[]"
			}
		],
		"payable": false,
		"stateMutability": "view",
		"type": "function"
	},
	{
		"constant": false,
		"inputs": [
			{
				"internalType": "string",
				"name": "title",
				"type": "string"
			},
			{
				"internalType": "string",
				"name": "description",
				"type": "string"
			},
			{
				"internalType": "uint256",
				"name": "durationInDays",
				"type": "uint256"
			},
			{
				"internalType": "uint256",
				"name": "amountToRaise",
				"type": "uint256"
			}
		],
		"name": "startCampaign",
		"outputs": [],
		"payable": false,
		"stateMutability": "nonpayable",
		"type": "function"
	}
]

const instance = new web3.eth.Contract(abi, address);

export default instance;
