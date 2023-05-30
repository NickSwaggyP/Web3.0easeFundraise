<template>
  <div>
    <a-card class="ant-card-shadow">
      <template #title>
        <h3>
          所有筹款
          <a-button style="float: right" @click="openModal" type="primary"
            >发起筹款</a-button
          >
        </h3>
      </template>
      <a-table
        :columns="columns"
        :loading="state.loading"
        :data-source="state.data"
      >
        <template #time="{text, record}">
          {{ new Date(text * 1000).toLocaleString() }}
        </template>
        <template #coverImage="{text, record}">
          <img style="width:100px;heigth:100px" :src="Url + text" />
        </template>

        <template #tag="{text, record}">
          <a-tag color="success" v-if="record.success === true">
            <template #icon>
              <check-circle-outlined />
            </template>
            筹款成功
          </a-tag>
          <a-tag
            color="processing"
            v-else-if="new Date(record.endTime * 1000) > new Date()"
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
        </template>
        <template #action="{text, record}">
          <a @click="clickFunding(record.index)">查看详情</a>
        </template>
      </a-table>
    </a-card>

    <Modal v-model:visible="isOpen">
      <a-card
        style="width: 600px; margin: 0 2em;"
        :body-style="{ overflowY: 'auto', maxHeight: '600px' }"
      >
        <template #title>
          <h3 style="text-align: center">发起筹款</h3>
        </template>
        <create-form
          v-if="show"
          :model="model"
          :form="form"
          :fields="fields"
          @reject="closeModal"
        />
      </a-card>
    </Modal>
  </div>
</template>

<script lang="ts">
import { defineComponent, ref, reactive, onMounted } from "vue";
import Modal from "../components/base/modal.vue";
import CreateForm from "../components/base/createForm.vue";
import { Model, Fields, Form } from "../type/form";
import { getCurrentInstance } from "vue";
const cxt: any = getCurrentInstance(); //相当于Vue2中的this
// const bus = cxt.appContext.config.globalProperties.$bus
import {
  contract,
  getAccount,
  getAllFundings,
  Funding,
  newFunding,
  returnDetail,
  addListener,
  getProve,
  newProve,
} from "../api/contract";
import { message } from "ant-design-vue";
import {
  CheckCircleOutlined,
  SyncOutlined,
  CloseCircleOutlined,
} from "@ant-design/icons-vue";
import { useRouter } from "vue-router";

const Url = 'https://ipfscc.bsngate.com:18602/ipfs/peer1/0e109dc62b50452fa9a4bc58b94c1a82/api/v0/cat?arg='

const columns = [
  {
    dataIndex: "title",
    key: "title",
    title: "筹款标题",
  },
  {
    title: "封面图",
    dataIndex: "coverImage",
    key: "coverImage",
    slots: { customRender: "coverImage" },
  },

  {
    title: "目标金额(UGAS/万人民币)",
    dataIndex: "goal",
    key: "goal",
  },
  {
    title: "目前金额(UGAS/万人民币)",
    dataIndex: "amount",
    key: "amount",
  },
  {
    title: "结束时间",
    dataIndex: "endTime",
    key: "endTime",
    slots: { customRender: "time" },
  },
  {
    title: "当前状态",
    dataIndex: "success",
    key: "success",
    slots: { customRender: "tag" },
  },
  {
    title: "详情",
    dataIndex: "action",
    key: "action",
    slots: { customRender: "action" },
  },
];

export default defineComponent({
  name: "Home",
  components: {
    Modal,
    CreateForm,
    CheckCircleOutlined,
    SyncOutlined,
    CloseCircleOutlined,
  },
  setup() {
    onMounted(() => {
      // bus.on('printMessage',()=>{
      //       closeModal()
      //   })
    });
    let show = ref<boolean>(false);
    const isOpen = ref<boolean>(false);
    const state = reactive<{ loading: boolean; data: Funding[] }>({
      loading: true,
      data: [],
    });

    async function fetchData() {
      state.loading = true;
      try {
        state.data = await getAllFundings();
        console.log(state.data.length);
        state.loading = false;
        // var res = await returnDetail(3);
        // console.log(res);
      } catch (e) {
        console.log(e);
        message.error("获取筹款失败!");
      }
    }

    async function openModal() {
      model.account = await getAccount();
      show.value = true;
      isOpen.value = true;
    }
    function closeModal() {
            show.value = false;

      isOpen.value = false;
    }

    let model = reactive<Model>({
      account: "",
      coverImage: "",
      title: "",
      info: "",
      amount: 0,
      date: null,
      details: [],
    });

    const fields = reactive<Fields>({
      account: {
        type: "input",
        label: "发起人",
        disabled: true,
      },
      title: {
        type: "input",
        label: "标题",
        rule: {
          required: true,
          trigger: "blur",
        },
      },
      info: {
        type: "textarea",
        label: "简介",
        rule: {
          required: true,
          trigger: "blur",
        },
      },
      coverImage: {
        type: "upload",
        label: "封面图",
        rule: {
          // required: true,
          trigger: "blur",
        },
      },
      amount: {
        type: "number",
        label: "目标金额",
        min: 0,
      },
      date: {
        type: "time",
        label: "截止日期",
      },
      details: {
        type: "autocomplete",
        label: "证明材料",
      },
    });

    const form = reactive<Form>({
      submitHint: "发起筹款",
      cancelHint: "取消",
      cancel: () => {
        model.coverImage="",
        model.account="",
        model.title="",
        model.info="",
        model.amount=0,
        model.date=null,
        model.details=[]
        
        console.log(model);

        closeModal();
      },
      finish: async () => {
        console.log(model);
        
        const seconds = Math.ceil(new Date(model.date).getTime() / 1000);
        try {
          const res = await newFunding(
            model.account,
            model.title,
            model.info,
            model.coverImage,
            model.details,
            model.amount,
            seconds
          );
         
          message.success("发起筹款成功");
          closeModal();
          fetchData();
        } catch (e) {
          console.log(e);
          message.error("发起筹款失败");
        }
      },
    });

    const router = useRouter();
    const clickFunding = (index: number) => {
      router.push(`/funding/${index}`);
    };
    addListener(fetchData);
    fetchData();

    return {
      openModal,
      isOpen,
      model,
      fields,
      form,
      Url,
      state,
      columns,
      clickFunding,
      closeModal,
      show
    };
  },
});
</script>
