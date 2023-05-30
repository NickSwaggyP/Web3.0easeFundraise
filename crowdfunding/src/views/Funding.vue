<template>
  <div>
    <a-card
      class="ant-card-shadow"
      :loading="state.loading"
      :tab-list="tabList"
      :active-tab-key="key"
      @tabChange="onTabChange"
    >
      <template #title>
        <h3>
          {{ state.data.title }}
          <span style="float:right">
            你捐助了 {{ state.myAmount }} UGAS/万人民币
            <a-button
              type="primary"
              v-if="
                new Date(state.data.endTime * 1000) > new Date() &&
                  state.data.success == false
              "
              @click="openModal"
              >我要捐助</a-button
            >
            <a-button
              type="danger"
              v-if="!state.data.success && state.myAmount != 0"
              @click="returnM"
              >退钱！</a-button
            >
          </span>
        </h3>
      </template>
      <a-descriptions bordered v-if="key === 'info'">
        <a-descriptions-item label="筹款标题" :span="2">
          {{ state.data.title }}
        </a-descriptions-item>
        <a-descriptions-item label="筹款发起人" :span="2">
          {{ state.data.initiator }}
        </a-descriptions-item>
        <a-descriptions-item label="截止日期" :span="2">
          {{ new Date(state.data.endTime * 1000).toLocaleString() }}
        </a-descriptions-item>
        <a-descriptions-item label="当前状态">
          <a-tag color="success" v-if="state.data.success === true">
            <template #icon>
              <check-circle-outlined />
            </template>
            筹款成功
          </a-tag>
          <a-tag
            color="processing"
            v-else-if="new Date(state.data.endTime * 1000) > new Date()"
          >
            <template #icon>
              <sync-outlined :spin="true" />
            </template>
            正在筹款
          </a-tag>
          <a-tag color="error" v-else>
            <template #icon>
              <close-circle-outlined />
            </template>
            筹款失败
          </a-tag>
        </a-descriptions-item>
        <a-descriptions-item label="目标金额">
          <a-statistic :value="state.data.goal">
            <template #suffix>
              UGAS/万人民币
            </template>
          </a-statistic>
        </a-descriptions-item>
        <a-descriptions-item label="当前金额">
          <a-statistic :value="state.data.amount">
            <template #suffix>
              UGAS/万人民币
            </template>
          </a-statistic>
        </a-descriptions-item>
        <a-descriptions-item label="筹款进度">
          <a-progress
            type="circle"
            :percent="
              state.data.success
                ? 100
                : (state.data.amount * 100) / state.data.goal
            "
            :width="80"
          />
        </a-descriptions-item>
        <a-descriptions-item label="筹款介绍" :span="8">
          {{ state.data.info }}
        </a-descriptions-item>
        <a-descriptions-item label="证明材料" :span="8">
          <div class="picList">
            <div class="details" v-for="(item, i) in details" :key="i">
              <img :src="item" alt="" />
            </div>
          </div>
        </a-descriptions-item>
        <a-descriptions-item label="证实情况" :span="8">
          <a-button type="primary" @click="showModal" class="prove">帮忙证实</a-button>
          <a-collapse v-model:activeKey="activeKey" >
            
            <a-collapse-panel
              key="1"
              header="证实情况"
              :style="customStyle"
             
            >
           <div class="send" v-if="!proveList.length&&!control.length">
             <h2>加载中</h2>
           </div>

         
           
                 <div  class="proveFather" v-if="proveList.length">
<div class="prove-item" v-for="(item,i) in proveList" :key="i"  >
                <div class="prove">
                  <img :src="item.picture" alt="">
                </div>
                <div class="item-header">
                  <div class="item-header-left">
                    与患者关系：{{item.relation}}
                  </div>
                  <div class="item-header-right">
                    证实信息：{{item.info}}
                  </div>
                </div>
                
              </div>
            </div>
           
            <div class="none" v-else-if="!proveList.length&&control.length">
            <h2>暂无</h2>
          </div>
            </a-collapse-panel>
          </a-collapse>
          <a-modal
            v-model:visible="visible"
            title="立即证实"
            @ok="handleOk"
            ok-text="确认"
            cancel-text="取消"
            @cancel="close"
            :confirmLoading="Loading"
          >
            <a-form
              :model="formState"
              :label-col="labelCol"
              :wrapper-col="wrapperCol"
              :rules="rules"
              ref="formRef"
            >
              <a-form-item label="证实内容" name="info">
                <a-input v-model:value="formState.info" />
              </a-form-item>
              <a-form-item label="证明材料" name="img">
                <a-upload
                  name="avatar"
                  list-type="picture-card"
                  class="avatar-uploader"
                  :show-upload-list="false"
                  :customRequest="upload"
                >
                  <img v-if="url" :src="url" alt="avatar" class="imgUrl" />
                  <div v-else>
                    <loading-outlined v-if="loading"></loading-outlined>
                    <plus-outlined v-else></plus-outlined>
                    <div class="ant-upload-text">+</div>
                    <div class="ant-upload-add">点击或拖拽上传</div>
                  </div>
                </a-upload>
              </a-form-item>
              <a-form-item label="与患者关系" name="relation">
                <a-input v-model:value="formState.relation" />
              </a-form-item>
            </a-form>
          </a-modal>
        </a-descriptions-item>
      </a-descriptions>

      <Use
        v-if="key === 'use'"
        :id="id"
        :data="state.data"
        :amount="state.myAmount"
      ></Use>
    </a-card>

    <Modal v-model:visible="isOpen">
      <a-card
        style="width: 600px; margin: 0 2em;"
        :body-style="{ overflowY: 'auto', maxHeight: '600px' }"
      >
        <template #title><h3 style="text-align: center">捐助</h3></template>
        <create-form :model="model" :form="form" :fields="fields" />
      </a-card>
    </Modal>
  </div>
</template>

<script lang="ts">
import axios from "axios";
import { defineComponent, ref, reactive, computed, onMounted } from "vue";
import {
  getOneFunding,
  Funding,
  getAccount,
  getMyFundingAmount,
  contribute,
  returnMoney,
  newProve,
  getProve,
  addListener,
  returnDetail,
} from "../api/contract";
import { useRoute } from "vue-router";
import { message } from "ant-design-vue";
import {
  CheckCircleOutlined,
  SyncOutlined,
  CloseCircleOutlined,
} from "@ant-design/icons-vue";
import Modal from "../components/base/modal.vue";
import CreateForm from "../components/base/createForm.vue";
import Use from "../components/Use.vue";
import { Model, Fields, Form } from "../type/form";

const column = [
  {
    dataIndex: "",
  },
];

const tabList = [
  {
    key: "info",
    tab: "项目介绍",
  },
  {
    key: "use",
    tab: "使用请求",
  },
];

export default defineComponent({
  name: "Funding",
  components: {
    Modal,
    CreateForm,
    CheckCircleOutlined,
    SyncOutlined,
    CloseCircleOutlined,
    Use,
  },
  setup() {
    onMounted(() => {
      returnDetails();
      returnProve();
    });
 
    let control:any=ref([])
    // =========基本数据==========
    const route = useRoute();
    const id = parseInt(route.params.id as string);
    const account = ref("");
    const state = reactive<{
      data: Funding | {};
      loading: boolean;
      myAmount: number;
    }>({
      data: {},
      loading: true,
      myAmount: 0,
    });
    const details = ref([]);

    //弹出框
    const visible = ref<boolean>(false);
    const showModal = () => {
      visible.value = true;
    };
    let loading = ref(false);
    const formState = reactive({
      info: "",
      relation: "",
      img: "",
    });
    const formRef = ref();
    const handleOk = async (e: MouseEvent) => {
      formRef.value
        .validate()
        .then(async () => {
          try {
            Loading.value = true;
            loading.value = true;
            const res = await newProve(
              id,
              formState.info,
              formState.relation,
              String(url.value)
            );

            message.success("证实成功");
            Loading.value = false;
            loading.value = false;
            visible.value = false;
      returnProve();
            formRef.value.resetFields();
            url.value = "";
          } catch (e) {
            console.log(e);
            message.error("证实失败");
          }
        })
        .catch(() => {
          console.log("error");
          message.error("请将信息填写完整");
        });
    };

    //---------------------------------------帮助证实-------------------------------
    const activeKey = ref(['1']);
    const text = ` found as a welcome guest in many households across the world.`;
    const customStyle =
      'background:#1890ff;border-radius: 4px;margin-bottom: 24px;border: 0;overflow: hidden;';
    const rules = {
      info: [{ required: true, message: "证实内容不能为空", trigger: "blur" }],
      img: [{ required: true, message: "证实图片不能为空", trigger: "blur" }],
      relation: [
        { required: true, message: "证实关系不能为空", trigger: "blur" },
        {
          min: 2,
          max: 5,
          message: "证实关系应该在 2 到 5字 之间",
          trigger: "blur",
        },
      ],
    };
    let urlContext = ref("");
    let url = ref("");
    //帮助证实（上传图片）

    const upload = async (e: any) => {
      var coverImage = e.file;
      var data = new FormData();
      data.append("arg", coverImage);
      var config = {
        method: "post",
        url:
          "https://ipfscc.bsngate.com:18602/ipfs/peer1/90e7dec9503c4696bc0def7ae820b523/api/v0/add?pin=true",
        // url: "https://api.pinata.cloud/pinning/pinFileToIPFS",
        // headers: {
        //   pinata_api_key: "cb75ec5381d05d8a3fe9",
        //   pinata_secret_api_key:
        //     "7718a452b603e3f685a137cef876d3064f61ae6c54707fb3d6e60059b9bd93c2",
        //   "Content-Type": `multipart/form-data`,
        // },
        data: data,
      };

      const res = await axios(config);

      urlContext.value = String(res.data.Hash);

      url.value =
        "https://ipfscc.bsngate.com:18602/ipfs/peer1/0e109dc62b50452fa9a4bc58b94c1a82/api/v0/cat?arg=" +
        String(urlContext.value);

      console.log(url.value);
      formState.img = url.value;
    };
    const close = () => {
      formRef.value.resetFields();
      url.value = "";
    };
    let Loading = ref(false);

    // ===========发起捐助表单============
    const isOpen = ref(false);
    function openModal() {
      isOpen.value = true;
    }
    function closeModal() {
      isOpen.value = false;
    }

    const model = reactive<Model>({
      value: 1,
    });
    const fields = reactive<Fields>({
      value: {
        type: "number",
        min: 0.00000000000001,
        label: "捐助金额",
      },
    });
    const form = reactive<Form>({
      submitHint: "捐助",
      cancelHint: "取消",
      cancel: () => {
        closeModal();
      },
      finish: async () => {
        try {
          await contribute(id, model.value);
          message.success("捐助成功");
          fetchData();
          closeModal();
        } catch (e) {
          message.error("捐助失败");
        }
      },
    });

    async function returnM() {
      try {
        await returnMoney(id);
        message.success("退钱成功");
        fetchData();
      } catch (e) {
        message.error("退钱失败");
      }
    }
    //============获取详情数据=========
    async function returnDetails() {
      try {
        var res = await returnDetail(id);
        console.log(res);
        details.value = res;
      } catch (e) {}
    }
    //============获取证实数据=========
    let proveList=ref([] as any[])
    async function returnProve() {
      try {
        var res = await getProve(id);
        console.log(res);
        proveList.value=res
        control.value=[1]
        console.log(control.value.length);
        
      } catch (e) {}
    }
    // =========切换标签页===========
    const key = ref("info");
    const onTabChange = (k: "use" | "info") => {
      key.value = k;
    };

    // =========加载数据===========
    async function fetchData() {
      state.loading = true;
      try {
        [state.data, state.myAmount] = await Promise.all([
          getOneFunding(id),
          getMyFundingAmount(id),
        ]);
        state.loading = false;
        //@ts-ignore
        fields.value.max = state.data.goal - state.data.amount;
      } catch (e) {
        console.log(e);
        message.error("获取详情失败");
      }
    }

    const dataSource = ref([]);

    addListener(fetchData);

    getAccount().then((res) => (account.value = res));
    fetchData();

    return {
      labelCol: { span: 6 },
      wrapperCol: { span: 14 },
      formState,
      state,
      account,
      isOpen,
      openModal,
      form,
      model,
      fields,
      tabList,
      key,
      details,
      onTabChange,
      id,
      returnM,
      returnDetails,
      visible,
      showModal,
      handleOk,
      url,
      upload,
      rules,
      formRef,
      close,
      Loading,
       activeKey,
      text,
      customStyle,
      proveList,
      control
    };
  },
});
</script>

<style>
.picList {
  display: flex;
}
.picList img {
  width: 200px;
  height: 200px;
  margin-right: 30px;
}
.prove{
  margin-bottom: 20px;
}
.prove-item{
  padding-left: 20px;
  border-bottom: 1px solid #dfdbdbc5;
text-align: center;
width: 100%;
display: flex;

}
.item-header{
  display: flex;
  flex-direction: column;
  justify-content: space-around;
  margin-left: 30px;
}
.proveFather{
  width: 100%;
}
.item-header-left{
  font-weight: 700;
  color: black;
}
.item-header-right{
  font-size: 13px;
}
.send{
  text-align: center;
  
}
.send h2{
  color: #1890ff!important;
}
</style>
