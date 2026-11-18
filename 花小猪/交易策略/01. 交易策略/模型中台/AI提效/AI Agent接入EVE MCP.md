---
title: "AI Agent接入EVE MCP"
source: https://cooper.didichuxing.com/knowledge/2199610335356/2210124566724
---

# AI Agent接入EVE MCP

## EVE-MCP介绍

EVE MCP Server 是基于 MCP (Model Context Protocol) 协议的服务，将 EVE 平台的深度模型训练相关接口封装为 MCP Tools，使 Claude 等 AI 助手可以直接调用这些接口，实现通过自然语言创建和管理深度学习训练任务。

| 功能 <br> | 说明 <br> |
| --- | --- |
| **创建训练任务** <br> | 通过3步流程快速创建深度模型训练任务 <br> |
| **查看训练日志** <br> | 实时获取训练任务的完整日志信息 <br> |
| **任务训练失败诊断** <br> | 根据训练日志，可自动诊断报错原因 <br> |
| **任务重跑** <br> | 重新运行当前任务产出新的批次 <br> |
| **任务管理** <br> | 查看历史任务、重新运行、停止任务等 <br> |
| **代码文件读写** <br> | 支持mcp读写代码文件 <br> |
| **配置文件快速创建任务** <br> | 支持从配置文件快速创建任务（具体用法参考第6点） <br> |

## 接入流程

### 申请访问令牌

- ✅ [申请访问令牌](https://mcphub.intra.xiaojukeji.com/square)（已有的令牌可复用）

1. **访问 MCP Hub**：点击访问 [MCP Hub](http://mcphub.intra.xiaojukeji.com/square?action=open_tokens)，访问令牌申请窗口会自动弹出

2. **创建令牌**：点击 **【创建新令牌】**。 

![](e3e420a7112fea84-image.png)

3. **填写信息**：在弹出的表单中，填写【API-KEY 描述】以及【D 盾动态码】，然后点击右下角 **【申请令牌】**。

![](bb72f0004c6649b3-image.png)

4. **保存密钥**：立即复制并妥善保存生成的访问令牌。

	- **注意**：生成成功后，关闭弹窗窗口，**将无法再次查看或复制该令牌**。

	- 请**立即复制**生成的 访问令牌。

	- 请妥善保存您的访问令牌，**切勿泄露给他人**。

![](6d687c8ca66824bb-image.png)

### 获取认证信息

联系 EVE 平台值班获取以下认证信息，**如果已有EVE平台openapi接口访问token和caller可复用**，无需再次申请

| 参数 <br> | Header 名称 <br> | 说明 <br> | 示例 <br> |
| --- | --- | --- | --- |
| 调用方标识 <br> | `EVE-OPENAPI-CALLER` <br> | EVE 平台调用方标识 <br> | `your_caller` <br> |
| 调用方Token <br> | `EVE-OPENAPI-TOKEN` <br> | EVE 平台认证 Token <br> | `your_token` <br> |
| [EVE项目空间 ID](https://ether.intra.xiaojukeji.com/projectManage/projectList) <br> | `EVE-PROJECT-NAMESPACE-ID` <br> | 项目空间 ID <br> | `1` <br>![](c57a638f9cc6577f-截屏2026-06-09_下午7.56.40.png) <br> |

### 配置 AI 智能体

在 AI 智能体中配置 MCP 服务。可查看 [MCPHub](https://mcphub.intra.xiaojukeji.com/square) 中提供的全部 MCP 服务。

不同的智能体，配置文件路径有所区别，常见路径为：`mcp.json`、`～/mcporter/mcportor.json` 等。

**说明：配置 MCP 服务，可查看 AI 智能体官网，查看客户端 / 桌面拓展 / 手动 JSON 等不同的配置方法。**

以WorkBuddy为例，提供了桌面配置方式。

MCP（Model Context Protocol）就是给 AI 加的“USB 接口”——让 WorkBuddy 能调用外部工具、业务系统和数据源，而不只是聊天。

**当前你机器上的状态**（`\~/.workbuddy/mcp.json`）：已配置 2 个 MCP Server，都指向本地网关 `127.0.0.1:28582`：

- `Cooper`：http 类型，带 Bearer 鉴权

- `eve-mcp`：streamable-http 类型，额外带 EVE 项目命名空间等 header

这两个已生效，所以我在对话里能直接调用 Cooper 的检索/读取、eve 的训练任务等工具。

**配置入口**：侧边栏「插件 / 连接器」→ 右上角「MCP 服务器」→「配置 MCP」，粘贴 JSON 保存；保存后需要在 MCP 列表里点「信任」并打开开关，工具才会在对话中可用。绿色指示灯=连接正常，红色=配置有误。

**配置文件位置**（二选一）：

- 用户级：`\~/.workbuddy/mcp.json` —— 一次配置，所有项目复用（通知类、常用服务放这里）

- 项目级：`<项目目录>/.workbuddy/mcp.json` —— 只对当前项目生效

**配置方式**：

json

```JSON
#国内正式环境
  "mcpServers": {
    "eve-mcp": {
      "type": "streamable-http",
      "url": "http://127.0.0.1:28582/v1/eve_mcp/eve_mcp",
      "headers": {
        "Authorization": "Bearer xxx",
        "EVE-OPENAPI-CALLER": "xxx",
        "EVE-OPENAPI-TOKEN": "xxx",
        "EVE-PROJECT-NAMESPACE-ID": "xxx"
      }
    }
  }

#国内花小猪环境
  "mcpServers": {
    "eve-mcp": {
      "type": "streamable-http",
      "url": "http://127.0.0.1:28582/v1/eve_hbg/eve_hbg",
      "headers": {
        "Authorization": "Bearer xxx",
        "EVE-OPENAPI-CALLER": "xxx",
        "EVE-OPENAPI-TOKEN": "xxx",
        "EVE-PROJECT-NAMESPACE-ID": "xxx"
      }
    }
  }

#美东正式环境-暂不支持，依赖底层域名系统helm那有问题，解析不了eve的域名
  "mcpServers": {
    "eve-mcp": {
      "type": "streamable-http",
      "url": "http://127.0.0.1:28582/v1/eve_us/eve_us",
      "headers": {
        "Authorization": "Bearer xxx",
        "EVE-OPENAPI-CALLER": "xxx",
        "EVE-OPENAPI-TOKEN": "xxx",
        "EVE-PROJECT-NAMESPACE-ID": "xxx"
      }
    }
  }
```

### 确保滴滴安全助手正常运行

使用 MCP 服务前，**必须完成以下操作，确保已登陆智能体安全防护。**

#### 打开智能体安全

点击打开滴滴安全助手【[智能体安全](https://z.didi.cn/94ieD)】，进入智能体安全功能项。如下图。

> 或通过安全助手图标【滴滴盾牌】进入，macOS 位于屏幕右上角，windows 位于屏幕右下角。

![](6adb28c6abbdffd7-image.png)

#### 登陆开启智能体安全防护

- **普通用户，直接扫码登陆**

![](2a62018462427a72-image.png)         ![](1378dfc86f6a7cf6-img_v3_0210r_3a34e6fd-e637-4793-962f-d8e33f545fcg.jpg)

### 使用AI Agent自动执行任务

![](f8ca95b09615dc71-image.png)

![](87c2b3b3693f68a3-image.png)
