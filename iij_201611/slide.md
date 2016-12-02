---

# mgcap: A Multi-thread Pcap capturing tool with Hardware timestamping

## sora, aom

---

# 高精度時刻同期+DC環境でのネットワーク計測を検討

* 想定アプリケーション
  - DCにおけるパケットキャプチャ、ping/OWD, ジッタ計測, など
* ほしい機能
  - Linux kernel, デバイスドライバで実現される各種機能 (PTP, VM環境, 仮想ネットワーク機能, etc)
  - Hardware支援を用いたパケットタイムスタンピング
* 性能目標
  - 一般的なユーザ環境に比べて、DC環境における平均パケット長はとても短い
  - 極端な例
    * Facebookで(Hadoopクラスタを除くと)200Byte以下 \[SIGCOMM'15\]
    * Googleで100Byte程度 \[NSDI'16\]
  - 10GE+平均パケット長100Bは11Mpps程度のパケット処理性能が必要

---

# アプローチ(1/2)
### Vanilla driverを使いつつ11Mpps処理のパケットIOを考える

![](https://raw.githubusercontent.com/sora/slide/master/iij_201611/images/approach1.png)

---

# アプローチ(2/2)

* 10GE環境の高PPSパケット処理方法は、Linux netdevとnetmap\[ATC'12\]でかなり整理されている
* 本検討(mgcap)でのアプローチ
  - 水平方向の性能改善
    * NIC TX/RX multiqueueを利用
    * Packet input/outputまでの処理を(できるだけ)cpu coreでisolation
  - 垂直方向の性能改善
    * qdisc-bypass
    * Bulk packet read/write (system call数の削減)
    * パケット処理プロセスがデバイスを占有

---

# Linuxのバニラドライバを用いたBypass Net.IOのうれしさ

*

---

# 他手法との対比

![](https://raw.githubusercontent.com/sora/slide/master/iij_201611/images/approach2.png)

---

# NIC TX/RX multiqueueの利用

---

# (できるだけ)パケット処理をcpu coreごとで行う

---

# Qdisc-bypass

---

# Bulk packet read/write (system call数の削減)

---

# (option) 使い方

---
# LinuxにおけるネットワークIOの性能の考え方

* 10Gbps以降のNIC性能は、

* 水平方向と垂直方向の性能を考える必要がある

---

# Two column layout

![](https://raw.githubusercontent.com/sora/slide/master/iij_201611/images/overview.png)

{.column}

1. hoge

---

# Slides can have an inline image

![](https://source.unsplash.com/WLUHO9A_xik/1600x900)

---

# Slides local images

---

# Slides can have many images

![](https://www.gstatic.com/images/branding/product/2x/drive_36dp.png){pad=10}
![](https://www.gstatic.com/images/branding/product/2x/docs_36dp.png){pad=10}
![](https://www.gstatic.com/images/branding/product/2x/sheets_36dp.png){pad=10}
![](https://www.gstatic.com/images/branding/product/2x/slides_36dp.png){pad=10}
![](https://www.gstatic.com/images/branding/product/2x/forms_36dp.png){pad=10}

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
