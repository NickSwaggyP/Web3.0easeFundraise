// import mitt from 'mitt'
import router from './router'
import { createApp } from 'vue'
// import ElementPlus from 'element-plus'
// import 'element-plus/dist/index.css'
import App from './App.vue'




import Antd from 'ant-design-vue';
import 'ant-design-vue/dist/antd.css';
import './index.css';

// @ts-ignore
const app=createApp(App)
app.use(router).use(Antd).mount('#app')

//  const bus = mitt()
 
// app.config.globalProperties.mittBus = new mitt()