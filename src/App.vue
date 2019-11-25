<template>
  <v-app style="background-image: url('http://meon.com.br/files/media/originals/banhado.jpg'); background-repeat: no-repeat; background-size: cover;" >
    <v-content>
      <v-container>
        <v-layout text-xs-center wrap>
          <v-flex mb-4>
            <h1 class="display-2 font-weight-bold mb-3">Ajude o Banhado</h1>
          </v-flex>
        </v-layout>

        <v-layout row justify-center>
          <v-dialog v-model="startCampaignDialog" max-width="600px" persistent>
            <v-btn slot="activator" color="primary" dark>Começar uma campanha</v-btn>
            <v-card>
              <v-card-title>
                <span class="headline font-weight-bold mt-2 ml-4">Comece sua campanha beneficente</span>
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
                    <v-flex xs12 >
                      <v-text-field label="Amount (ETH)" type="number" step="0.0001" min="0" v-model="newCampaign.amountGoal">
                      </v-text-field>
                    </v-flex>
                    <v-flex xs12>
                      <v-text-field label="Duration in days" min="1" type="number" v-model="newCampaign.duration">
                      </v-text-field>
                    </v-flex>
                  </v-layout>
                </v-container>
              </v-card-text>
              <v-card-actions>
                <v-spacer></v-spacer>
                <v-btn color="blue darken-1" flat @click="startCampaignDialog = false; newCampaign.isLoading = false;">
                  Fechar
                </v-btn>
                <v-btn color="blue darken-1" flat @click="startCampaign" :loading="newCampaign.isLoading">
                  Salvar
                </v-btn>
              </v-card-actions>
            </v-card>
          </v-dialog>
        </v-layout>
      </v-container>

      <v-container style="max-width: 400px;" grid-list-lg>
        <h1 style="color: white;" class="display-1 font-weight-bold mb-3">Campanhas esperando aprovação</h1>
        <v-layout row wrap>
          <v-flex v-for="(campaign, index) in campaignData" v-if="stateMap[campaign.currentState].text === 'Ongoing' && campaign.approved === false" :key="index" xs12>
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
                    Fechar
                  </v-btn>
                </v-card-actions>
              </v-card>
            </v-dialog>
            <v-hover>
              <v-card
                slot-scope="{ hover }"
                :class="`elevation-${hover ? 10 : 2}`"
                style="max-width: 400px;"
              >
                <v-card-title primary-title>
                  <div>
                    <div class="headline font-weight-bold">
                      {{ campaign.campaignTitle }}
                    </div>
                    <br/>
                    <span>{{ campaign.campaignDesc }}</span>
                    <br/><br/>
                    <small>Aberto até: <b>{{ new Date(campaign.deadline * 1000) }}</b></small>
                    <br/><br/>
                    <small>Objetivo <b>{{ campaign.goalAmount / 10**18 }} ETH </b></small>
                    <small v-if="campaign.currentState == 1">Objetivo não alcançado até o fim da campanha</small>
                    <small v-if="campaign.currentState == 2">Objetivo foi alcançado</small>
                  </div>
                </v-card-title>
                <v-flex
                  class="d-flex ml-3" xs12 sm6 md3>
                  <v-btn
                    class="mt-3"
                    color="light-blue darken-1 white--text"
                    @click="vote(index)"
                    :loading="campaign.isLoading"
                  >
                    votar
                  </v-btn>
                </v-flex>
                <v-card-actions style="margin-left: 30px" v-if="campaign.currentState == 0" class="text-xs-center">
                  <v-progress-circular
                    height="10"
                    :color="stateMap[campaign.currentState].color"
                    :value="(campaign.currentAmount / campaign.goalAmount) * 100"
                    size="150"
                    rotate="180"
                    width="10"
                  ></v-progress-circular>
                  <span class="font-weight-bold" style="width: 200px;">
                    {{ campaign.currentAmount / 10**18 }} ETH / {{ campaign.goalAmount / 10**18 }} ETH
                  </span>
                </v-card-actions>
              </v-card>
            </v-hover>
          </v-flex>
        </v-layout>
      </v-container>

      <v-container style="max-width: 400px;" grid-list-md>
        <h1 style="color: white;" class="display-1 font-weight-bold mb-3">Campanhas em Andamento</h1>
        <v-layout row wrap>
          <v-flex v-for="(campaign, index) in campaignData" v-if="stateMap[campaign.currentState].text === 'Ongoing' && campaign.approved === true" :key="index" xs12>
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
                    Fechar
                  </v-btn>
                </v-card-actions>
              </v-card>
            </v-dialog>
            <v-hover>
              <v-card
                slot-scope="{ hover }"
                :class="`elevation-${hover ? 10 : 2}`"
                style="max-width: 400px;"
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
                    <span>{{ campaign.campaignDesc }}</span>
                    <br/><br/>
                    <span class="font-weight-bold"">
                      Doações: {{ campaign.campaignDonators}}
                    </span>
                    <br/><br/>
                    <small>Aberto até: <b>{{ new Date(campaign.deadline * 1000) }}</b></small>
                    <br/><br/>
                    <small>Objetivo <b>{{ campaign.goalAmount / 10**18 }} ETH </b></small>
                    <small v-if="campaign.currentState == 1">Objetivo não alcançado até o fim da campanha</small>
                    <small v-if="campaign.currentState == 2">Objetivo foi alcançado</small>
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
                    style="min-width: 200px;"
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
                    style="min-width: 200px;"
                    :loading="campaign.isLoading"
                  >
                    Get refund
                  </v-btn>
                </v-flex>
                <v-card-actions style="margin-left: 30px" v-if="campaign.currentState == 0" class="text-xs-center">

                  <v-progress-circular
                    height="10"
                    :color="stateMap[campaign.currentState].color"
                    :value="(campaign.currentAmount / campaign.goalAmount) * 100"
                    size="150"
                    rotate="180"
                    width="10"
                  ></v-progress-circular>
                  <span class="font-weight-bold" style="width: 200px;">
                    {{ campaign.currentAmount / 10**18 }} ETH / {{ campaign.goalAmount / 10**18 }} ETH
                  </span>
                </v-card-actions>
              </v-card>
            </v-hover>
          </v-flex>
        </v-layout>
      </v-container>
      <v-container style="max-width: 400px;" grid-list-lg>
        <h1 style="color: white;" class="display-1 font-weight-bold mb-3">Campanhas Finalizadas</h1>
        <v-layout align-center="true" align-self-center="true" row wrap>
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
                    Fechar
                  </v-btn>
                </v-card-actions>
              </v-card>
            </v-dialog>
            <v-hover>
              <v-card
                slot-scope="{ hover }"
                :class="`elevation-${hover ? 10 : 2}`"
                style="max-width: 400px;"
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
                    <span>{{ campaign.campaignDesc }}</span>
                    <br/><br/>
                    <small>Aberto até: <b>{{ new Date(campaign.deadline * 1000) }}</b></small>
                    <br/><br/>
                    <small>Objetivo <b>{{ campaign.goalAmount / 10**18 }} ETH </b></small>
                    <small v-if="campaign.currentState == 1">Objetivo não alcançado até o fim da campanha</small>
                    <small v-if="campaign.currentState == 2">Objetivo foi alcançado</small>
                  </div>
                </v-card-title>
                <v-card-actions style="margin-left: 30px" v-if="campaign.currentState == 2" class="text-xs-center">
                  <v-progress-circular
                    width="10"
                    size="150"
                    rotate="180"
                    :color="stateMap[campaign.currentState].color"
                    :value="(campaign.goalAmount / campaign.goalAmount) * 100"
                  ></v-progress-circular>
                  <br/><br/>
                  <span class="font-weight-bold" style="width: 200px;">
                    {{ campaign.goalAmount / 10**18 }} ETH / {{ campaign.goalAmount / 10**18 }} ETH
                  </span>
                </v-card-actions>
              </v-card>
            </v-hover>
          </v-flex>
        </v-layout>
      </v-container>
      <v-container style="max-width: 400px;" grid-list-lg>
        <h1 style="color: white;" class="display-1 font-weight-bold mb-3">Campanhas Expiradas</h1>
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
                    Fechar
                  </v-btn>
                </v-card-actions>
              </v-card>
            </v-dialog>
            <v-hover>
              <v-card
                slot-scope="{ hover }"
                :class="`elevation-${hover ? 10 : 2}`"
                style="max-width: 400px;"
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
                    <span>{{ campaign.campaignDesc }}</span>
                    <br/><br/>
                    <small>Aberto até: <b>{{ new Date(campaign.deadline * 1000) }}</b></small>
                    <br/><br/>
                    <small>Objetivo <b>{{ campaign.goalAmount / 10**18 }} ETH </b></small>
                    <small v-if="campaign.currentState == 1">Objetivo não alcançado até o fim da campanha</small>
                    <small v-if="campaign.currentState == 2">Objetivo foi alcançado</small>
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
                    style="min-width: 200px;"
                    :loading="campaign.isLoading"
                  >
                    Get refund
                  </v-btn>
                </v-flex>
                <v-card-actions style="margin-left: 30px" v-if="campaign.currentState == 3" class="text-xs-center">
                  <v-progress-circular
                    height="10"
                    :color="stateMap[campaign.currentState].color"
                    :value="(campaign.currentAmount / campaign.goalAmount) * 100"
                    size="150"
                    rotate="180"
                    width="10"
                  ></v-progress-circular>
                  <span class="font-weight-bold" style="width: 200px;">
                    {{ campaign.currentAmount / 10**18 }} ETH / {{ campaign.goalAmount / 10**18 }} ETH
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
    vote(index){
      this.campaignData[index].isLoading = true;
      this.campaignData[index].contract.methods.vote().send({
        from: this.account,
      }).then(() => {
        this.campaignData[index].isLoading = false;
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
      console.log(this.campaignData[index].campaignDonators);
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
