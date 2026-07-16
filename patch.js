// ============================================================
//  sub-web 前端补丁（兼容 Vue 2）
//  MutationObserver 持续拦截 + 精确删除
// ============================================================

(function () {
  "use strict";

  var ACL4SSR_CONFIGS = [
    {
      label: "ACL4SSR",
      options: [
        { label: "ACL4SSR_Online 默认版 分组比较全", value: "https://raw.githubusercontent.com/ACL4SSR/ACL4SSR/master/Clash/config/ACL4SSR_Online.ini" },
        { label: "ACL4SSR_Online_Mini 精简版 带港美日国家", value: "https://raw.githubusercontent.com/ACL4SSR/ACL4SSR/master/Clash/config/ACL4SSR_Online_Mini.ini" },
        { label: "ACL4SSR_Online_Full 全分组 重度用户使用", value: "https://raw.githubusercontent.com/ACL4SSR/ACL4SSR/master/Clash/config/ACL4SSR_Online_Full.ini" },
        { label: "ACL4SSR_Online_Full_MultiMode 全分组 多模式", value: "https://raw.githubusercontent.com/ACL4SSR/ACL4SSR/master/Clash/config/ACL4SSR_Online_Full_MultiMode.ini" },
        { label: "ACL4SSR_Online_Full_NoAuto 全分组 无自动测速", value: "https://raw.githubusercontent.com/ACL4SSR/ACL4SSR/master/Clash/config/ACL4SSR_Online_Full_NoAuto.ini" },
        { label: "ACL4SSR_Online_Full_AdblockPlus 全分组 更多去广告", value: "https://raw.githubusercontent.com/ACL4SSR/ACL4SSR/master/Clash/config/ACL4SSR_Online_Full_AdblockPlus.ini" },
        { label: "ACL4SSR_Online_Full_Netflix 全分组 奈飞全量", value: "https://raw.githubusercontent.com/ACL4SSR/ACL4SSR/master/Clash/config/ACL4SSR_Online_Full_Netflix.ini" },
        { label: "ACL4SSR_Online_Full_Google 全分组 谷歌细分", value: "https://raw.githubusercontent.com/ACL4SSR/ACL4SSR/master/Clash/config/ACL4SSR_Online_Full_Google.ini" },
        { label: "ACL4SSR_Online_Mini_MultiCountry 精简版 多国分组", value: "https://raw.githubusercontent.com/ACL4SSR/ACL4SSR/master/Clash/config/ACL4SSR_Online_Mini_MultiCountry.ini" },
        { label: "ACL4SSR_Online_MultiPlatform 多平台版", value: "https://raw.githubusercontent.com/ACL4SSR/ACL4SSR/master/Clash/config/ACL4SSR_Online_MultiPlatform.ini" },
      ],
    },
    { label: "default", options: [
        { label: "No-Urltest", value: "https://cdn.jsdelivr.net/gh/SleepyHeeead/subconverter-config@master/remote-config/universal/no-urltest.ini" },
        { label: "Urltest", value: "https://cdn.jsdelivr.net/gh/SleepyHeeead/subconverter-config@master/remote-config/universal/urltest.ini" },
    ]},
    { label: "customized", options: [
        { label: "Maying", value: "https://cdn.jsdelivr.net/gh/SleepyHeeead/subconverter-config@master/remote-config/customized/maying.ini" },
        { label: "Ytoo", value: "https://cdn.jsdelivr.net/gh/SleepyHeeead/subconverter-config@master/remote-config/customized/ytoo.ini" },
        { label: "FlowerCloud", value: "https://cdn.jsdelivr.net/gh/SleepyHeeead/subconverter-config@master/remote-config/customized/flowercloud.ini" },
        { label: "Nexitally", value: "https://cdn.jsdelivr.net/gh/SleepyHeeead/subconverter-config@master/remote-config/customized/nexitally.ini" },
        { label: "SoCloud", value: "https://cdn.jsdelivr.net/gh/SleepyHeeead/subconverter-config@master/remote-config/customized/socloud.ini" },
        { label: "ARK", value: "https://cdn.jsdelivr.net/gh/SleepyHeeead/subconverter-config@master/remote-config/customized/ark.ini" },
        { label: "ssrCloud", value: "https://cdn.jsdelivr.net/gh/SleepyHeeead/subconverter-config@master/remote-config/customized/ssrcloud.ini" },
    ]},
  ];

  var UA_PRESETS = [
    { label: "clash.meta", value: "clash.meta" },
    { label: "ClashForAndroid/2.5.12", value: "ClashForAndroid/2.5.12" },
    { label: "ClashX Pro/1.90.0", value: "ClashX Pro/1.90.0" },
    { label: "Quantumult X/1.0.0", value: "Quantumult%20X/1.0.0" },
    { label: "Surge/5.0", value: "Surge/5.0" },
    { label: "Shadowrocket", value: "Shadowrocket" },
    { label: "V2Box/1.0", value: "V2Box/1.0" },
    { label: "Stash/1.0", value: "Stash/1.0" },
  ];

  var STORAGE_KEY_UA = "sub-converter-custom-ua";
  function getUA() { try { return localStorage.getItem(STORAGE_KEY_UA) || ""; } catch (e) { return ""; } }
  function saveUA(v) { try { localStorage.setItem(STORAGE_KEY_UA, v); } catch (e) {} }

  // ---- 防重入标志 ----
  var cleaning = false;

  // ---- 持续清理 ----
  function startCleaner() {
    var REMOVE_LABELS = ["后端地址", "订阅短链"];

    function clean() {
      if (cleaning) return;
      cleaning = true;

      // 1. 移除匹配标签的 form-item
      document.querySelectorAll(".el-form-item__label").forEach(function (label) {
        var text = (label.textContent || "").trim();
        for (var i = 0; i < REMOVE_LABELS.length; i++) {
          if (text.indexOf(REMOVE_LABELS[i]) !== -1) {
            var item = label.closest(".el-form-item");
            if (item && item.parentNode) {
              item.parentNode.removeChild(item);
            }
            break;
          }
        }
      });

      // 2. 精确移除「生成短链接」按钮（只删按钮本身，不删父容器）
      document.querySelectorAll("button").forEach(function (btn) {
        if ((btn.textContent || "").indexOf("生成短链接") !== -1) {
          btn.parentNode.removeChild(btn);
        }
      });

      cleaning = false;
    }

    clean();

    var observer = new MutationObserver(function (mutations) {
      for (var i = 0; i < mutations.length; i++) {
        if (mutations[i].addedNodes.length > 0) {
          clean();
          return;
        }
      }
    });
    observer.observe(document.body, { childList: true, subtree: true });
  }

  // ---- 注入自定义UA ----
  function injectUA() {
    if (document.getElementById("custom-ua-field")) return;
    var remoteFormItem = null;
    document.querySelectorAll(".el-form-item__label").forEach(function (label) {
      if ((label.textContent || "").indexOf("远程配置") !== -1) {
        remoteFormItem = label.closest(".el-form-item");
      }
    });
    if (!remoteFormItem) return;

    var savedUA = getUA();
    var opts = UA_PRESETS.map(function (p) {
      return '<option value="' + p.value + '">' + p.label + "</option>";
    }).join("");

    var div = document.createElement("div");
    div.id = "custom-ua-field";
    div.className = "el-form-item";
    div.innerHTML =
      '<label class="el-form-item__label" style="width:140px;float:left;line-height:36px;padding:0 12px 0 0;box-sizing:border-box;">自定义UA:</label>' +
      '<div class="el-form-item__content" style="margin-left:140px;">' +
        '<div style="display:flex;gap:8px;">' +
          '<select id="ua-preset" class="el-input__inner" style="width:200px;height:36px;">' +
            '<option value="">预设选择</option>' + opts +
          '</select>' +
          '<input id="ua-input" class="el-input__inner" placeholder="留空则使用客户端默认UA" value="' +
            savedUA.replace(/"/g, "&quot;") + '" style="flex:1;height:36px;" />' +
        '</div>' +
      '</div>';

    remoteFormItem.parentNode.insertBefore(div, remoteFormItem.nextSibling);
    document.getElementById("ua-preset").addEventListener("change", function () {
      if (this.value) { document.getElementById("ua-input").value = this.value; saveUA(this.value); }
    });
    document.getElementById("ua-input").addEventListener("input", function () { saveUA(this.value); });
  }

  // ---- 替换远程配置 ----
  function patchConfig() {
    var app = document.getElementById("app");
    if (!app || !app.__vue__) return;
    function walk(c) {
      if (c.$data && c.$data.options && c.$data.options.remoteConfig) c.$data.options.remoteConfig = ACL4SSR_CONFIGS;
      if (c.$children) c.$children.forEach(walk);
    }
    walk(app.__vue__);
  }

  // ---- 拦截订阅链接追加 ua ----
  function interceptUA() {
    new MutationObserver(function () {
      var ua = getUA();
      if (!ua) return;
      document.querySelectorAll("input[disabled], textarea[disabled]").forEach(function (el) {
        var v = el.value;
        if (v && v.indexOf("/sub?") !== -1 && v.indexOf("ua=") === -1) {
          el.value = v + "&ua=" + encodeURIComponent(ua);
          el.dispatchEvent(new Event("input", { bubbles: true }));
        }
      });
    }).observe(document.body, { childList: true, subtree: true, characterData: true });
  }

  // ---- 启动 ----
  function init() {
    startCleaner();
    patchConfig();
    interceptUA();
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", function () {
      setTimeout(init, 300);
      setTimeout(injectUA, 1000);
      setTimeout(injectUA, 2000);
    });
  } else {
    setTimeout(init, 300);
    setTimeout(injectUA, 1000);
    setTimeout(injectUA, 2000);
  }
})();
