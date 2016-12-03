---

# mgcap: A Multi-thread Pcap capturing tool with Hardware timestamping

## sora, aom

---

# 高精度時刻同期+DC環境でのネットワーク計測を検討

* 想定アプリケーション
  - パケットキャプチャ、ping/OWD, ジッタ計測など
* サポートしたい機能
  - Linuxの各種機能との併用 (PTP, VM, 仮想ネットワーク機能, etc)
  - Hardware支援を用いたパケットタイムスタンピング
  - 10GEが整備されたデータセンタで十分機能する性能

---

# 性能目標

* ユーザ環境に比べて、DC環境における平均パケット長は短い
* 極端な例
  - Facebookで(Hadoopクラスタを除くと)200Byte以下 \[SIGCOMM'15\]
  - Googleで100Byte程度 \[NSDI'16\]
    * 10GE+平均パケット長100Bは11Mpps程度のパケット処理性能が必要
* 今回は、Vanilla driverを使いつつ11Mpps処理のパケットIOを考える
  - Google Maglevは同様のアプローチだが、論文では詳細不明

---

# アプローチ

![](https://raw.githubusercontent.com/sora/slide/master/iij_201611/images/approach.png)

{.column}

* 高PPSパケット処理は、Linux kernelとnetmap\[ATC'12\]を参考
* 本実装で使うアプローチ
  - 垂直方向の性能
    * kernel-bypass
    * Bulk packet read/write
  - 水平方向の性能
    * Multi-core CPU
    * Multi-queue NIC

---

# kernel-bypass

![](https://raw.githubusercontent.com/sora/slide/master/iij_201611/images/bypass.png)

---

# Bulk packet read/write

* per packetによるsystem callの発行はオーバヘッドになる
* そこで、パケットを束ねて(Bulk) 1度のsystemcallで読み書き
* netmap/DPDKなどでは32個程度をBulk処理

---

# Parallel

* Multi-queue NIC
  - 高機能NICは、送受信ともに複数のHardware queue(HW Queue)に対応
  - 受信時は、NICがルールベースでHW Queueを選択
  - 送信時は、ソフトウェア側で送信HW Queueを選択
  - VMベースのクラウド環境ではVFごとに1 HW Queue割り当てなどで利用
* Multi-core CPU
  - RSS(Receive Side Scaling)によって、マルチコアでパケットを分散処理
  - 必要な時以外、CPUを横断せずisolationして処理

---

# mgcap (PacketIO) + mgdump(Packet capture)

* パケットキャプチャツール
* だいたいのLinux network deviceで動作
* Vanilla kernel対応 (**AWSなどのクラウド環境で利用可能**)
* PCAPファイルフォーマット対応
* 96 Byte snaplen (default value)
* (とりあえず)iproute2コマンドでのコンフィグ

---

# mgcap (PacketIO) + mgdump(Packet capture)

![](https://raw.githubusercontent.com/sora/slide/master/iij_201611/images/overview.png)

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

# qdisc-bypass

```c
// rx_handlerの登録
rc = netdev_rx_handler_register(gc->dev, mgc_handle_frame, mgc);

(snip)

// mgc_handle_frame
rx_handler_result_t mgc_handle_frame(struct sk_buff ** pskb)
{
    rx_handler_result_t res = RX_HANDLER_CONSUMED;

    /* 受信パケット処理: CPU毎に用意したring bufにデータを追加*/

    return res;
}
```

---

# read(2)のみでの可変長bulk read

```c
static ssize_t mgcap_read(...) {
    ...

    if (ring_empty(&rx->buf))
        return 0;

    copy_len = ring_count(&rx->buf);

    copy_to_user(buf, rx->buf.read, copy_len);

    ring_read_next(&rx->buf, copy_len);

    return copy_len;
}
```

---

# Multi-core CPUサポート

* User space
  - CPU coreごとにmgcapデバイスをopen(2)
  - pthreadを利用
  - CPUコアごとでthreadを立ち上げるためにpthread_setaffinity_npを利用
* kernel space
  - read(2)は、各cpu coreごとに呼ばれるため、smp_processor_id()で判定
    * `struct rxring *rx = &mgc->rxrings[smp_processor_id()];`

---

# pcapとpcap-ngにおけるナノ秒TStamp対応

* pcap、pcan-ngともにナノ秒タイムスタンプに対応済み
  - pcap: pcap_hdr_s構造体のmagic_numberを変更 (0xa1b2c3d4 -> 0xa1b23c4d)
  - pcapng: if_tsresol=9にし、Enhanched Packet Blockを使用
* pcap-ngのパケットデータ構造は、高速処理に向いていないので今回はpcapを選択

---

# 受信パフォーマンス

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
