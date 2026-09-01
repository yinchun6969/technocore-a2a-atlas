# Technocore A2A Atlas

[English](README.en.md)

把 **Technocore A2A v5.5.2** 三 Agent 签名协作流程与 **Atlas v3.9 Pixel Quest**
观察面板整合为一个安全入口。当前为安装候选版：优先支持已有 Technocore DID 与
A2A 节点的升级；裸机与新 DID 通过独立双语向导进入，避免安装器替用户创建或上传私钥。

## 已通过的真实验收

- 工作流：`wf-1788182002-f0269bdf77`
- 阶段：`WORKFLOW_TASK → BUILD_RESULT → CHALLENGE → REVISED_RESULT → COMPLETE`
- 状态：`ARTIFACT_VERIFIED`
- evidence：已验证，缺失阶段为零，结构化错误为零
- Merkle root：`c4153f36437243b3f143bcb68d0b8714ea09c77c24aec0bc8d7d8db388d9b596`

这证明的是签名阶段与证据包一致，不代表 Agent 永久在线，也不自动证明研究结论正确。

## 安装模型

| 节点 | A2A 角色 | Atlas |
| --- | --- | --- |
| Love8 | Scout / 派发与终局签名 | 不安装 |
| Aizong | Builder / 构建与修订 | 不安装 |
| AI2AI | Reviewer / 挑战与证据验证 | 安装 v3.9 |
| 手机/电脑 | SSH 与浏览器控制端 | 通过本地端口转发访问 |

Atlas 始终监听 `127.0.0.1:8787`，不要将端口直接暴露到公网。手机和电脑通过 SSH
本地转发访问，并不是在手机上伪造三个服务器 Agent。

## 快速检查

在每台已有 A2A 节点的 VPS 上下载项目后先运行：

```bash
sudo bash install.sh --check --role auto --atlas auto
```

确认输出角色正确且所有 preflight 通过后，再应用：

```bash
sudo bash install.sh --apply --role auto --atlas auto
```

安装器会从不可变 Git 提交检出源代码，验证实际 HEAD，按检测到的角色执行：

- AI2AI：A2A 收敛、v5.5.2 evidence/receipt、Atlas v3.9；
- Aizong：A2A 收敛、Builder 持久化游标轮询；
- Love8：A2A 收敛、出站去重重试、入站持久化游标轮询。

默认 `--check` 不修改文件、服务、密钥、房间或状态。`--apply` 只处理当前节点；
不会从一台主机远程登录另外两台主机。

## 新用户和新 DID

如果未检测到现有 A2A 运行时，安装器会以 `ONBOARDING_REQUIRED` 停止。使用固定版本的
双语 DID 向导导入现有 Ed25519 DID，或在本机创建新 DID。私钥权限为 `0600`，不会打印、
上传或提交到 GitHub。完整三节点裸机自动编排仍在后续里程碑中，在完成跨主机事务与回滚
测试前不会冒充“一键成功”。

```bash
bash onboard.sh --check --lang zh
bash onboard.sh --apply --lang zh
```

## 手机与电脑访问 Atlas

```bash
ssh -N -L 8787:127.0.0.1:8787 USER@AI2AI_HOST
```

保持连接后访问 `http://127.0.0.1:8787/`。Android SSH 客户端填写：本地端口
`8787`、远端主机 `127.0.0.1`、远端端口 `8787`。

## 安全边界

- 固定 A2A、Atlas 与 DID 向导源提交；
- 不读取、复制或显示私钥；
- 角色不匹配时停止；
- Atlas 仅允许安装在 AI2AI Reviewer 节点；
- 不倒退 mailbox cursor，不伪造 `COMPLETE`；
- 每个底层组件保留自己的备份和回滚路径。

## 开发验证

```bash
bash tests/test_release.sh
```

正式发布前还需要完成三台干净 Ubuntu VPS 的全新安装矩阵、重复安装测试、断网恢复测试，
以及从电脑和 Android SSH 隧道访问 Atlas 的验收。
