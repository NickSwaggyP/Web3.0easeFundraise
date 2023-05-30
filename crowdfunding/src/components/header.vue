<template>
  <header>
    <nav :class="['nav', {'nav-active': scrollTop > 0}]">
      <a class="logo"><img src="../../asset/logo.png"></a>
      <router-link to="/">所有筹款</router-link>
      <router-link to="/myself">我的筹款</router-link>
      <span :style="{ flex: 1 }"></span>
      <a @click="handleClick">{{account}}</a>
    </nav>
    <h1 class="title">
      Web3.0--安心筹
    </h1>
  </header>
</template>

<script lang="ts">
import { ref, onMounted, toRefs, defineComponent } from 'vue'
import { useRouter } from 'vue-router'
import { message } from 'ant-design-vue'
import { authenticate, getAccount, addListener } from '../api/contract'

export default defineComponent({
  setup() {
    // 滚动事件
    const scrollTop = ref(0)
    onMounted(() => {
      window.addEventListener('scroll', () => {
        scrollTop.value =
          window.pageYOffset ||
          document.documentElement.scrollTop ||
          document.body.scrollTop
      })
    })
    // 认证
    const account = ref('认证')
    async function handleClick() {
      await authenticate()
      account.value = await getAccount()
    }

    handleClick()
    addListener(handleClick)

    return { scrollTop, handleClick, account }
  },
})
</script>

<style scoped>
header {
  height: 25vh;
  background: url('/header.png') no-repeat;
  background-size: 100% 150%;
}
header .nav {
  display: flex;
  align-items: center;
  padding: 0 10em;
  position: fixed;
  left: 0;
  right: 0;
  transition: all 0.3s ease;
  z-index: 10;
}
@media screen and (max-width: 800px) {
  header .nav {
    padding: 0;
  }
}
header .nav a {
  line-height: 50px;
  padding: 0 1em;
  border: 3px solid transparent;
  color: white;
  transition: all 0.3s ease;
}
header .nav a:hover {
  background: var(--hover-background);
  border-top-color: var(--hover-color);
}
header .nav a.router-link-active,
header .nav a.router-link-exact-active {
  border-top-color: var(--choose-color);
}
header .nav a.logo {
  padding: 0;
}
header .nav a.logo img {
  width: 0;
  height: 50px;
  opacity: 0;
  transition: all 0.3s ease;
}
header .nav:hover,
header .nav.nav-active {
  background: #fff;
  box-shadow: var(--shadow);
}
header .nav:hover a,
header .nav.nav-active a {
  color: #333;
}
header .nav.nav-active a.logo {
  padding: 0 1em;
}
header .nav.nav-active a.logo img {
  width: 50px;
  opacity: 1;
}
.title {
  position: absolute;
  left: 4em;
  top: 3em;
  color: white;
  text-shadow: #ff0000 0 0 10px;
}
</style>