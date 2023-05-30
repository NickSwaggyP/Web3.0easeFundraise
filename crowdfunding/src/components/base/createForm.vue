<template>
  <a-form :model="model"
          :rules="rules"
          :layout="layout"
          @finish="finish"
          v-bind="itemLayout">
    <a-form-item v-for="(field, name) in fields"
                 :label="field.label"
                 :key="field.label"
                 :name="name">
      <a-input v-if="field.type === 'input'"
               v-model:value="model[name]"
               :disabled="field.disabled" />
      <a-input-password v-if="field.type === 'password'"
                        v-model:value="model[name]"
                        :disabled="field.disabled" />
      <a-input-number v-if="field.type === 'number'"
                      v-model:value="model[name]"
                      :min="field.min"
                      :max="field.max"
                      style="width: 240px"
                      :disabled="field.disabled"
                      string-mode
                      :formatter="(value) => `UGAS ${value}`"
                      :parser="(value) => value.replace(/UGAS|\s/g, '')" />
      <a-textarea v-if="field.type === 'textarea'"
                  v-model:value="model[name]"
                  :disabled="field.disabled"
                  autoSize />

      <a-upload v-if="field.type === 'upload'"
                name="avatar"
                list-type="picture-card"
                class="avatar-uploader"
                :show-upload-list="false"
                :customRequest="upload">
        <img v-if="url && field.type === 'upload'"
             :src="url"
             alt="avatar"
             class="imgUrl" />
        <div v-else>
          <loading-outlined v-if="loading"></loading-outlined>
          <plus-outlined v-else></plus-outlined>
          <div class="ant-upload-text">+</div>
          <div class="ant-upload-add">点击或拖拽上传</div>
        </div>
      </a-upload>

      <!-- @preview="handlePreview"  -->
      <a-upload v-if="field.type === 'autocomplete'"
                :file-list="fileList"
                :customRequest="uploadDetail"
                list-type="picture-card"
                @preview="handlePreview"
                :remove="
          (file) => {
            removeFile(file, 'header');
          }
        ">
        <div v-if="fileList.length < 8">
          <plus-outlined />
          <div style="margin-top: 0px"
               class="ant-upload-text">+</div>
          <div class="ant-upload-add">点击或拖拽上传</div>

        </div>
      </a-upload>
      <!-- <a-modal :visible="previewVisible" :title="previewTitle" :footer="null" @cancel="handleCancel">
      <img alt="example" style="width: 100%" :src="previewImage" />
    </a-modal> -->

      <!-- <input
        v-if="field.type === 'upload'"
        type="file"
        class="upload"
        @change="upload"
      /> -->
      <!-- <img :src="url" v-if="url && field.type === 'upload'" alt="" /> -->

      <!-- <a-upload v-if="field.type === 'upload'"
                v-model:file-list="fileList"
                name="avatar"
                list-type="picture-card"
                class="avatar-uploader"
                :show-upload-list="false"
                action="https://www.mocky.io/v2/5cc8019d300000980a055e76"
                :before-upload="beforeUpload"
                @change="handleChange">
        <img v-if="imageUrl"
             :src="imageUrl"
             alt="avatar" />
        <div v-else>
          <loading-outlined v-if="loading"></loading-outlined>
          <plus-outlined v-else></plus-outlined>
          <div class="ant-upload-text">Upload</div>
        </div>
      </a-upload> -->

      <a-radio-group v-if="field.type === 'radio'"
                     v-model:value="model[name]"
                     :disabled="field.disabled">
        <a-radio v-for="radio in field.radios"
                 :value="radio.value">
          {{ radio.hint }}
        </a-radio>
      </a-radio-group>
      <a-select v-if="field.type === 'select'"
                v-model:value="model[name]"
                :disabled="field.disabled">
        <a-select-option v-for="item in field.select"
                         :value="item">{{
          item
        }}</a-select-option>
      </a-select>
      <a-date-picker show-time
                     placeholder="选择时间"
                     v-if="field.type === 'time'"
                     v-model:value="model[name]" />
      <slot v-if="field.customRender"
            :name="field.customRender.slot"
            :field="field">
      </slot>
    </a-form-item>
    <a-form-item :wrapper-col="form.layout === 'inline' ? {} : { offset: 4 }">
      <a-button type="primary"
                html-type="submit"
                :loading="submitLoading"
                :disabled="nowFileUploadingCnt !== 0 || form.canSubmit === false">
        {{ form.submitHint || "提交" }}
      </a-button>
      <a-divider type="vertical" />
      <a-button type="default"
                @click="form.cancel"
                v-if="form.cancel">{{
        form.cancelHint || "取消"
      }}</a-button>
    </a-form-item>
  </a-form>
</template>

<script>
import { PropType, ref, reactive } from "vue";
import { UploadOutlined } from "@ant-design/icons-vue";
import { message } from "ant-design-vue";
// import { PlusOutlined } from '@ant-design/icons-vue';

export default {
  name: "CreateForm",
  components: { UploadOutlined },
  props: {
    model: Object,
    fields: Object,
    form: Object,
  },
  setup (props) {
    // 生成规则和文件以及自动补全等需要的函数
    const rules = reactive({});
    const nowFileUploadingCnt = ref(0);
    const CopyFields = reactive({});
    // const fileList = ref([]);
    let url = ref("");
    const details = reactive([]);
    let previewVisible = ref(false);
    const previewImage = ref("");
    const previewTitle = ref("");

    const fileList = ref([]);

    // const handleCancel = () => {
    //   previewVisible.value = false;
    //   previewTitle.value = '';
    // };

    for (let x in props.fields) {
      let field = props.fields[x];
      CopyFields[x] = {};
      // 如果有规则
      if (field.rule) {
        rules[x] = props.fields[x].rule;
        if (rules[x].required && !rules[x].validator)
          rules[x].message = `${field.label}不能为空!`;
      }
    }

    const upload = async (e) => {
      console.log(e.file);
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
      const res = await window.axios(config);
      props.model.coverImage = String(res.data.Hash);
      console.log(String(res.data.Hash));
      console.log(props.model.coverImage);

      url.value =
        "https://ipfscc.bsngate.com:18602/ipfs/peer1/0e109dc62b50452fa9a4bc58b94c1a82/api/v0/cat?arg=" +
        props.model.coverImage;
      console.log(url);
    };

    const uploadDetail = async (e) => {
      console.log(e.file);
      var coverImage = e.file;
      var data = new FormData();
      data.append("arg", coverImage);

      // var config = {
      //   method: "post",
      //   url: "http://81.68.160.150:8091/uploadfiles",
      //   data: data,
      // };
      var config = {
        method: "post",
        url:
          "https://ipfscc.bsngate.com:18602/ipfs/peer1/90e7dec9503c4696bc0def7ae820b523/api/v0/add?pin=true",
        data: data,
      };
      const res = await window.axios(config);


      var url = "https://ipfscc.bsngate.com:18602/ipfs/peer1/0e109dc62b50452fa9a4bc58b94c1a82/api/v0/cat?arg=" + String(res.data.Hash)

      props.model.details.push(url);
      console.log(props.model.details, "11111111");
      previewImage.value = url;
      fileList.value.push({
        uid: `${e.file.uid}`,
        name: `${e.file.name}`,
        status: "done",
        url: `${url}`,
      });
    };
    const self = this;
    const cancel = function (e) {
      //  bus.emit('printMessage')
      //  resetFields()
    };

    let _this = this;

    const removeFile = (file) => {
      console.log(file);
      fileList.value.forEach((item, index) => {
        if (item.uid === file.uid) {
          fileList.value.splice(index, 1);
        }
      });
      props.model.details.forEach((item,index)=>{
        if(item==file.url){
          props.model.details.splice(index,1);
        }
      })
    };


    // 提交函数
    const submitLoading = ref(false);
    const finish = async () => {
      submitLoading.value = true;
      try {
        await props.form.finish();
      } catch (e) {
      } finally {
        submitLoading.value = false;
      }
    };

    // 布局
    const layout = ref(props.form.layout || "horizontal");
    const itemLayout = ref(
      layout.value === "horizontal"
        ? { labelCol: { span: 4 }, wrapperCol: { span: 20 } }
        : {}
    );

    return {
      rules,
      finish,
      submitLoading,
      layout,
      itemLayout,
      nowFileUploadingCnt,
      CopyFields,
      upload,
      fileList,
      url,
      details,
      uploadDetail,
      previewVisible,
      previewImage,

      previewTitle,
      cancel,

      removeFile,
    };
  },
};
</script>

<style>
img {
  margin-top: 10px;
  width: 70px;
  height: 80px;
}
.ant-upload-text {
  font-size: 30px;
  color: rgb(224, 222, 222);
  /* padding-bottom: 8px; */
}
.ant-upload.ant-upload-select-picture-card {
  border: 1px solid #d9d9d9 !important;
}
.ant-upload.ant-upload-select-picture-card:hover {
  border: 1px solid rgb(24, 144, 255) !important;
}
.ant-upload.ant-upload-select-picture-card > .ant-upload {
  padding: 0 !important;
}
.imgUrl {
  margin: 0 !important;
}
.ant-upload-list-item-image {
  margin: 0 !important;
}
.ant-upload-list-item-thumbnail {
  height: 100% !important;
}
.ant-upload-add{
   font-size: 10px;
  color: rgb(161, 157, 157);
}
</style>
