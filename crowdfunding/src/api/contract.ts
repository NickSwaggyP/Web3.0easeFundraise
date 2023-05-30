import Web3 from "web3";
//@ts-ignore
import CrowdFunding from "./CrowdFunding.json";

//@ts-ignore
const web3 = new Web3(window.ethereum);
const contract = new web3.eth.Contract(
  CrowdFunding.abi,
  // "0x5C9d6F69361385aC8B6cCab206DbaD4e202353B5"
  // "0x3F586126662bCD3CF70FC06dAa55fEd2DcD64116"
  "0x88Ee8BC04b4B0B752D4cd9ecb08D6eF13eAfc440"//polo
  // "0x1F30Bf5155db62d31E289C0C46f45E6De372E74c"//local
);

function addListener(fn: Function) {
  //@ts-ignore
  ethereum.on("accountsChanged", fn);
}

export declare interface Funding {
  index: number;
  title: string;
  coverImage: string;
  details: Array<string>;
  info: string;
  goal: number;
  endTime: number;
  initiator: string;
  over: boolean;
  success: boolean;
  amount: number;
  numFunders: number;
  numUses: number;
  numProves: number;
  myAmount?: number;
}

export declare interface Use {
  index: number;
  info: string;
  goal: string;
  agreeAmount: string;
  disagree: string;
  over: boolean;
  agree: number; // 0: 没决定，1同意，2不同意
}

export declare interface Prove {
  index: number;
  info: string;
  relation: string;
  picture: string;
}

async function authenticate() {
  //@ts-ignore
  await window.ethereum.enable();
}

async function getAccount() {
  return (await web3.eth.getAccounts())[0];
}

async function getAllFundings(): Promise<Funding[]> {
  const length = await contract.methods.numFundings().call();
  const result = [];
  for (let i = 1; i <= length; i++) result.push(await getOneFunding(i));
  return result;
}

async function getOneFunding(index: number): Promise<Funding> {
  const data = await contract.methods.fundings(index).call();
  data.goal = Web3.utils.fromWei(data.goal, "ether");
  data.amount = Web3.utils.fromWei(data.amount, "ether");

  return { index, ...data };
}

async function getMyFundingAmount(index: number): Promise<number> {
  const account = await getAccount();
  console.log(contract.methods.getMyFundings(account, index).call() ,"4444");
  return parseFloat(
    Web3.utils.fromWei(
      await contract.methods.getMyFundings(account, index).call(),
      "ether"
    )
  );
}

async function getMyFundings(): Promise<{ init: Funding[]; contr: Funding[] }> {
  const account = await getAccount();
  const all = await getAllFundings();
  const result: {
    init: Funding[];
    contr: Funding[];
  } = {
    init: [],
    contr: [],
  };
  console.log(account, "account");
  for (let funding of all) {
    console.log(funding.initiator, "funding.initiator");
    const myAmount = await getMyFundingAmount(funding.index);
    // console.log(myAmount, "111111111111");
    if (funding.initiator == account) {
      result.init.push({
        myAmount,
        ...funding,
      });
    }
    if (myAmount != 0) {
      result.contr.push({
        myAmount,
        ...funding,
      });
    }
  }
  return result;
}

async function contribute(id: number, value: number) {
  // value = 0.001;
  // console.log(value);
  return await contract.methods.contribute(id).send({
    from: await getAccount(),
    value: Web3.utils.toWei(value.toString(10), "ether"),
  });
}

async function newFunding(
  account: string,
  title: string,
  info: string,
  coverImage: string,
  details: Array<string>,
  amount: number,
  seconds: number
) {
  return await contract.methods
    .newFunding(
      account,
      title,
      info,
      coverImage,
      details,
      Web3.utils.toWei(amount.toString(10), "ether"),
      seconds
    )
    .send({
      from: account,
      gas: 1000000,
    });
}


async function getAllUse(id: number): Promise<Use[]> {
  const length = await contract.methods.getUseLength(id).call();
  const account = await getAccount();
  const rusult: Use[] = [];
  for (let i = 1; i <= length; i++) {
    const use = await contract.methods.getUse(id, i, account).call();
    rusult.push({
      index: i,
      info: use[0],
      goal: Web3.utils.fromWei(use[1], "ether"),
      agreeAmount: Web3.utils.fromWei(use[2], "ether"),
      disagree: Web3.utils.fromWei(use[3], "ether"),
      over: use[4],
      agree: use[5],
    });
  }
  return rusult;
}

async function getProve(id: number): Promise<Prove[]> {
  const length = await contract.methods.getProveLength(id).call();
  const account = await getAccount();
  const res: Prove[] = [];
  for (let i = 1; i <= length; i++) {
    const pro = await contract.methods.getProve(id, i).call();
    res.push({
      index: i,
      info: pro[0],
      relation: pro[1],
      picture: pro[2],
    });
  }
  return res;
}

async function agreeUse(id: number, useID: number, agree: boolean) {
  const accont = await getAccount();
  return await contract.methods.agreeUse(id, useID, agree).send({
    from: accont,
    gas: 1000000,
  });
}

async function newUse(id: number, goal: number, info: string) {
  const account = await getAccount();
  const eth = Web3.utils.toWei(goal.toString(10), "ether");
  return await contract.methods.newUse(id, eth, info).send({
    from: account,
    gas: 1000000,
  });
}
async function newProve(id: number,info: string, relation: string,picture: string) {
  const account = await getAccount();
  return await contract.methods.newProve(id, info,relation,picture).send({
    from: account,
    gas: 1000000,
  });
}
async function returnDetail(id: number) {
  const details = await contract.methods.getDetails(id).call();
  return details;
}

async function returnMoney(id: number) {
  const account = await getAccount();
  return await contract.methods.returnMoney(id).send({
    from: account,
    gas: 1000000,
  });
}

export {
  getAccount,
  authenticate,
  contract,
  getAllFundings,
  getOneFunding,
  getMyFundingAmount,
  contribute,
  newFunding,
  returnDetail,
  getAllUse,
  agreeUse,
  newUse,
  getMyFundings,
  returnMoney,
  getProve,
  newProve,
  addListener,
};
