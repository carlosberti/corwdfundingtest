<template>
  <v-app class="blue lighten-3">
    <v-content>
      <v-container>
        <v-layout text-xs-center wrap>
          <v-flex mb-4>
            <h1 class="display-2 font-weight-bold mb-3">Crowdfunding</h1>
            <p class="subheading font-weight-regular">Utilizing Ethereum for Decentralized Crowdfunding</p>
          </v-flex>
        </v-layout>

        <v-layout row justify-center>
          <v-dialog v-model="startCampaignDialog" max-width="600px" persistent>
            <v-btn slot="activator" color="primary" dark>Start a Campaign</v-btn>
            <v-card>
              <v-card-title>
                <span class="headline font-weight-bold mt-2 ml-4">Bring your campaign to life</span>
              </v-card-title>
              <v-card-text class="pt-0">
                <v-container class="pt-0" grid-list-md>
                  <v-layout wrap>
                    <v-flex xs12>
                      <v-text-field label="Title" persistent-hint v-model="newCampaign.title">
                      </v-text-field>
                    </v-flex>
                    <v-flex xs12>
                      <v-textarea label="Description" persistent-hint v-model="newCampaign.description">
                      </v-textarea>
                    </v-flex>
                    <v-flex xs12 sm6>
                      <v-text-field label="Amount Needed (ETH)" type="number" step="0.0001" min="0" v-model="newCampaign.amountGoal">
                      </v-text-field>
                    </v-flex>
                    <v-flex xs12 sm6>
                      <v-text-field label="Duration (in days)" min="1" type="number" v-model="newCampaign.duration">
                      </v-text-field>
                    </v-flex>
                  </v-layout>
                </v-container>
              </v-card-text>
              <v-card-actions>
                <v-spacer></v-spacer>
                <v-btn color="blue darken-1" flat @click="startCampaignDialog = false; newCampaign.isLoading = false;">
                  Close
                </v-btn>
                <v-btn color="blue darken-1" flat @click="startCampaign" :loading="newCampaign.isLoading">
                  Save
                </v-btn>
              </v-card-actions>
            </v-card>
          </v-dialog>
        </v-layout>
      </v-container>

      <v-container grid-list-lg>
        <h1 class="display-1 font-weight-bold mb-3">Campaigns OnGoing</h1>
        <v-layout row wrap>
          <v-flex v-for="(campaign, index) in campaignData" v-if="stateMap[campaign.currentState].text === 'Ongoing'" :key="index" xs12>
            <v-dialog v-model="campaign.dialog" width="800">
              <v-card>
                <v-card-title class="headline font-weight-bold">
                  {{ campaign.campaignTitle }}
                </v-card-title>
                <v-card-text>
                  {{ campaign.campaignDesc }}
                </v-card-text>
                <v-card-actions>
                  <v-spacer></v-spacer>
                  <v-btn color="blue darken-1" flat="flat" @click="campaignData[index].dialog = false">
                    Close
                  </v-btn>
                </v-card-actions>
              </v-card>
            </v-dialog>
            <v-hover>
              <v-card
                slot-scope="{ hover }"
                :class="`elevation-${hover ? 10 : 2}`"
              >
                <v-card-title primary-title>
                  <div>
                    <div class="headline font-weight-bold">
                      <v-chip
                        label
                        :color="stateMap[campaign.currentState].color"
                        text-color="white" class="mt-0">
                      {{ stateMap[campaign.currentState].text }}
                      </v-chip>
                      {{ campaign.campaignTitle }}
                    </div>
                    <br/>
                    <span>{{ campaign.campaignDesc.substring(0, 100) }}</span>
                    <span v-if="campaign.campaignDesc.length > 100">
                      ... <a @click="campaignData[index].dialog = true">[Show full]</a>
                    </span>
                    <br/><br/>
                    <small>Up Until: <b>{{ new Date(campaign.deadline * 1000) }}</b></small>
                    <br/><br/>
                    <small>Goal of <b>{{ campaign.goalAmount / 10**18 }} ETH </b></small>
                    <small v-if="campaign.currentState == 1">wasn't achieved before deadline</small>
                    <small v-if="campaign.currentState == 2">has been achieved</small>
                  </div>
                </v-card-title>
                <v-flex
                  v-if="campaign.currentState == 0 && account != campaign.campaignOwner"
                  class="d-flex ml-3" xs12 sm6 md3>
                  <v-text-field
                    label="Amount (in ETH)"
                    type="number"
                    step="0.0001"
                    min="0"
                    v-model="campaign.fundAmount"
                  ></v-text-field>
                  <v-btn
                    class="mt-3"
                    color="light-blue darken-1 white--text"
                    @click="fundCampaign(index)"
                    :loading="campaign.isLoading"
                  >
                    Fund
                  </v-btn>
                </v-flex>
                <v-flex v-if="account != campaign.campaignOwner" class="d-flex ml-3" xs12 sm6 md3>
                  <v-btn
                    class="mt-3"
                    color="brown darken-1 white--text"
                    @click="getRefundFundRaising(index)"
                    :loading="campaign.isLoading"
                  >
                    Get refund
                  </v-btn>
                </v-flex>
                <v-card-actions v-if="campaign.currentState == 0" class="text-xs-center">
                  <span class="font-weight-bold" style="width: 200px;">
                    {{ campaign.currentAmount / 10**18 }} ETH
                  </span>
                  <v-progress-linear
                    height="10"
                    :color="stateMap[campaign.currentState].color"
                    :value="(campaign.currentAmount / campaign.goalAmount) * 100"
                  ></v-progress-linear>
                  <span class="font-weight-bold" style="width: 200px;">
                    {{ campaign.goalAmount / 10**18 }} ETH
                  </span>
                </v-card-actions>
              </v-card>
            </v-hover>
          </v-flex>
        </v-layout>
      </v-container>
      <v-container grid-list-lg>
        <h1 class="display-1 font-weight-bold mb-3">Campaigns Completed</h1>
        <v-layout row wrap>
          <v-flex v-for="(campaign, index) in campaignData" v-if="stateMap[campaign.currentState].text === 'Completed'" :key="index" xs12>
            <v-dialog v-model="campaign.dialog" width="800">
              <v-card>
                <v-card-title class="headline font-weight-bold">
                  {{ campaign.campaignTitle }}
                </v-card-title>
                <v-card-text>
                  {{ campaign.campaignDesc }}
                </v-card-text>
                <v-card-actions>
                  <v-spacer></v-spacer>
                  <v-btn color="blue darken-1" flat="flat" @click="campaignData[index].dialog = false">
                    Close
                  </v-btn>
                </v-card-actions>
              </v-card>
            </v-dialog>
            <v-hover>
              <v-card
                slot-scope="{ hover }"
                :class="`elevation-${hover ? 10 : 2}`"
              >
                <v-card-title primary-title>
                  <div>
                    <div class="headline font-weight-bold">
                      <v-chip
                        label
                        :color="stateMap[campaign.currentState].color"
                        text-color="white" class="mt-0">
                      {{ stateMap[campaign.currentState].text }}
                      </v-chip>
                      {{ campaign.campaignTitle }}
                    </div>
                    <br/>
                    <span>{{ campaign.campaignDesc.substring(0, 100) }}</span>
                    <span v-if="campaign.campaignDesc.length > 100">
                      ... <a @click="campaignData[index].dialog = true">[Show full]</a>
                    </span>
                    <br/><br/>
                    <small>Up Until: <b>{{ new Date(campaign.deadline * 1000) }}</b></small>
                    <br/><br/>
                    <small>Goal of <b>{{ campaign.goalAmount / 10**18 }} ETH </b></small>
                    <small v-if="campaign.currentState == 1">wasn't achieved before deadline</small>
                    <small v-if="campaign.currentState == 2">has been achieved</small>
                  </div>
                </v-card-title>
                <v-card-actions v-if="campaign.currentState == 2" class="text-xs-center">
                  <span class="font-weight-bold" style="width: 200px;">
                    {{ campaign.goalAmount / 10**18 }} ETH
                  </span>
                  <v-progress-linear
                    height="10"
                    :color="stateMap[campaign.currentState].color"
                    :value="(campaign.goalAmount / campaign.goalAmount) * 100"
                  ></v-progress-linear>
                  <span class="font-weight-bold" style="width: 200px;">
                    {{ campaign.goalAmount / 10**18 }} ETH
                  </span>
                </v-card-actions>
              </v-card>
            </v-hover>
          </v-flex>
        </v-layout>
      </v-container>
      <v-container grid-list-lg>
        <h1 class="display-1 font-weight-bold mb-3">Campaigns Expired</h1>
        <v-layout row wrap>
          <v-flex v-for="(campaign, index) in campaignData" v-if="stateMap[campaign.currentState].text === 'Expired'" :key="index" xs12>
            <v-dialog v-model="campaign.dialog" width="800">
              <v-card>
                <v-card-title class="headline font-weight-bold">
                  {{ campaign.campaignTitle }}
                </v-card-title>
                <v-card-text>
                  {{ campaign.campaignDesc }}
                </v-card-text>
                <v-card-actions>
                  <v-spacer></v-spacer>
                  <v-btn color="blue darken-1" flat="flat" @click="campaignData[index].dialog = false">
                    Close
                  </v-btn>
                </v-card-actions>
              </v-card>
            </v-dialog>
            <v-hover>
              <v-card
                slot-scope="{ hover }"
                :class="`elevation-${hover ? 10 : 2}`"
              >
                <v-card-title primary-title>
                  <div>
                    <div class="headline font-weight-bold">
                      <v-chip
                        label
                        :color="stateMap[campaign.currentState].color"
                        text-color="white" class="mt-0">
                      {{ stateMap[campaign.currentState].text }}
                      </v-chip>
                      {{ campaign.campaignTitle }}
                    </div>
                    <br/>
                    <span>{{ campaign.campaignDesc.substring(0, 100) }}</span>
                    <span v-if="campaign.campaignDesc.length > 100">
                      ... <a @click="campaignData[index].dialog = true">[Show full]</a>
                    </span>
                    <br/><br/>
                    <small>Up Until: <b>{{ new Date(campaign.deadline * 1000) }}</b></small>
                    <br/><br/>
                    <small>Goal of <b>{{ campaign.goalAmount / 10**18 }} ETH </b></small>
                    <small v-if="campaign.currentState == 1">wasn't achieved before deadline</small>
                    <small v-if="campaign.currentState == 2">has been achieved</small>
                  </div>
                </v-card-title>
                <v-flex
                  v-if="campaign.currentState == 0 && account != campaign.campaignOwner"
                  class="d-flex ml-3" xs12 sm6 md3>
                  
                </v-flex>
                <v-flex v-if="account != campaign.campaignOwner" class="d-flex ml-3" xs12 sm6 md3>
                  <v-btn
                    class="mt-3"
                    color="brown darken-1 white--text"
                    @click="getRefundFundRaising(index)"
                    :loading="campaign.isLoading"
                  >
                    Get refund
                  </v-btn>
                </v-flex>
                <v-card-actions v-if="campaign.currentState == 3" class="text-xs-center">
                  <span class="font-weight-bold" style="width: 200px;">
                    {{ campaign.currentAmount / 10**18 }} ETH
                  </span>
                  <v-progress-linear
                    height="10"
                    :color="stateMap[campaign.currentState].color"
                    :value="(campaign.currentAmount / campaign.goalAmount) * 100"
                  ></v-progress-linear>
                  <span class="font-weight-bold" style="width: 200px;">
                    {{ campaign.goalAmount / 10**18 }} ETH
                  </span>
                </v-card-actions>
              </v-card>
            </v-hover>
          </v-flex>
        </v-layout>
      </v-container>
    </v-content>
  </v-app>
</template>

<script>
// We import our the scripts for the smart contract instantiation, and web3
import crowdfundInstance from '../contracts/crowdfundInstance';
import crowdfundCampaign from '../contracts/crowdfundCampaignInstance';
import web3 from '../contracts/web3';

export default {
  name: 'App',
  data() {
    return {
      startCampaignDialog: false,
      account: null,
      stateMap: [
        { color: 'primary', text: 'Ongoing' },
        { color: 'warning', text: 'Expired' },
        { color: 'success', text: 'Completed' },
      ],
      campaignData: [],
      newCampaign: { isLoading: false },
    };
  },
  mounted() {
    web3.eth.getAccounts().then((accounts) => {
      [this.account] = accounts;
      this.getCampaigns();
    });
  },
  methods: {
    getCampaigns() {
      crowdfundInstance.methods.returnAllCampaigns().call().then((campaign) => {
        campaign.forEach((campaignAddress) => {
          const campaignInst = crowdfundCampaign(campaignAddress);
          campaignInst.methods.getDetails().call().then((campaignData) => {
            const campaignInfo = campaignData;
            campaignInfo.isLoading = false;
            campaignInfo.contract = campaignInst;
            this.campaignData.push(campaignInfo); 
          });
        });
      });
    },
    startCampaign() {
      if(this.newCampaign.duration < 1){
        return;
      }
      this.newCampaign.isLoading = true;
      crowdfundInstance.methods.startCampaign(
        this.newCampaign.title,
        this.newCampaign.description,
        this.newCampaign.duration,
        web3.utils.toWei(this.newCampaign.amountGoal, 'ether'),
      ).send({
        from: this.account,
      }).then((res) => {
        const campaignInfo = res.events.CampaignStarted.returnValues;
        campaignInfo.isLoading = false;
        campaignInfo.currentAmount = 0;
        campaignInfo.currentState = 0;
        campaignInfo.contract = crowdfundCampaign(campaignInfo.coAddress);
        this.startCampaignDialog = false;
        this.newCampaign = { isLoading: false };
      });
    },
    fundCampaign(index) {
      if (!this.campaignData[index].fundAmount) {
        return;
      }

      const campaignContract = this.campaignData[index].contract;
      this.campaignData[index].isLoading = true;
      campaignContract.methods.contribute().send({
        from: this.account,
        value: web3.utils.toWei(this.campaignData[index].fundAmount, 'ether'),
      }).then((res) => {
        const newTotal = parseInt(res.events.FundingReceived.returnValues.currentTotal, 10);
        const campaignGoal = parseInt(this.campaignData[index].goalAmount, 10);
        this.campaignData[index].currentAmount = newTotal;
        this.campaignData[index].isLoading = false;

        // Set campaign state to success
        if (newTotal >= campaignGoal) {
          this.campaignData[index].currentState = 2;
        }
      });
    },
    getRefund(index) {
      this.campaignData[index].isLoading = true;
      this.campaignData[index].contract.methods.getRefund().send({
        from: this.account,
      }).then(() => {
        this.campaignData[index].isLoading = false;
      });
    },
    getRefundFundRaising(index) {
      this.campaignData[index].isLoading = true;
      this.campaignData[index].contract.methods.getRefundFundRaising().send({
        from: this.account,
      }).then(() => {
        this.campaignData[index].isLoading = false;
      });
    },
  },
};
</script>
