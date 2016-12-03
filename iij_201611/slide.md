---

# mgcap: A Multi-thread Pcap capturing tool with Hardware timestamping

## sora, aom

---

# 高精度時刻同期+DC環境でのネットワーク計測を検討

* 想定アプリケーション
  - パケットキャプチャ、ping/OWD, ジッタ計測など
* ほしい機能
  - Linuxの各種機能との併用 (PTP, VM, 仮想ネットワーク機能, etc)
  - Hardware支援を用いたパケットタイムスタンピング
  - 10GEが整備されたデータセンタで十分機能する性能

---

# 性能目標

* 一般的なユーザ環境に比べて、DC環境における平均パケット長はとても短い
* 極端な例
  - Facebookで(Hadoopクラスタを除くと)200Byte以下 \[SIGCOMM'15\]
  - Googleで100Byte程度 \[NSDI'16\]
    * 10GE+平均パケット長100Bは11Mpps程度のパケット処理性能が必要
* 今回は、Vanilla driverを使いつつ11Mpps処理のパケットIOを考える

---

# アプローチ

![](https://raw.githubusercontent.com/sora/slide/master/iij_201611/images/approach.png)

{.column}

* 高PPSパケット処理は、Linux kernelとnetmap\[ATC'12\]を参考にする
* 本実装で使うアプローチ
  - 垂直方向の性能改善
    * qdisc-bypass
    * Bulk packet read/write
  - 水平方向の性能改善
    * Multi-core CPU
    * Multi-queue NIC

---

# qdis-bypass

![](https://raw.githubusercontent.com/sora/slide/master/iij_201611/images/bypass.png)

---

# Bulk packet read/write

hoge

---

# Multi-core CPU

```c
// kernel


```

---

# Multi-queue NIC

moge

---

# mgcap (PacketIO) + mgdump(Packet capture)

![](https://raw.githubusercontent.com/sora/slide/master/iij_201611/images/overview.png)

{.column}

* パケットキャプチャツール
* ほぼすべてのLinuxのnetdeviceで動作
* PCAP with high-resolution timestamping (e.g., Intel X550, etc)
* 96 Byte snaplen (default value)
* iproute2コマンドでのコンフィグ(廃止予定)

---

# 使い方

```bash
# packet capture
$ insmod kmod/mgcap.ko
$ ./ip/ip mgcap lo
$ ./ip/ip mgcap set dev lo mode drop
$ ls /dev/mgcap/lo
$ cd mgcap; ./mgdump /dev/mgcap/lo
$ ping 127.0.0.1 &
$ tshark -r ./output0.pcap
$ rmmod mgcap

# set HWTStamp
$ cd src/tools
$ ./mgcap_hwtstamp_config enp1s0f1 1
```

---

# HPIO (Hayai Packet IO)

* 今回のmgcapからkernel moduleを取り出して汎用化したもの (with upa)
* 対応(予定)機能
  - 汎用パケットIO化 (snaplenを取り除く)
  - 送信機能 (writev with O_NONBLOCK?)
  - read/write --> readv/writev
  - 仮想デバイス
* アプリケーション
  - Bridge/Forwarding
  - pktgen
  - Metric monitoring

---

# pcapとpcap-ngにおけるナノ秒TStamp対応

hoge

---

# Slides can have code

```javascript
// Print hello
function hello() {
  console.log('Hello world');
}
```

---
# Slides can have tables

Animal | Number
-------|--------
Fish   | 142 million
Cats   | 88 million
Dogs   | 75 million
Birds  | 16 million
