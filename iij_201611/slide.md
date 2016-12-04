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

# mgcap(PacketIO) + mgdump(Packet capture)

![](https://raw.githubusercontent.com/sora/slide/master/iij_201611/images/mgdump.png)

---

# 使い方

```bash
# packet capture
$ insmod kmod/mgcap.ko
$ ./ip/ip mgcap lo
$ ./ip/ip mgcap set dev lo mode drop
$ ls /dev/mgcap/lo
$ cd mgcap; ./mgdump /dev/mgcap/lo
$ ping -c 5 127.0.0.1
$ rmmod mgcap
$ tshark -r ./output0.pcap

# enable HWTStamp
$ cd src/tools
$ ./mgcap_hwtstamp_config enp1s0f1 1
```

---

$ mgdump /dev/mgcap/enp1s0f1

```bash
~/wrk/mgcap/src/mgdump# ./mgdump /dev/mgcap/enp1s0f1
ncpus=8
mgdump: thread 0: start. cur_cpu=0
mgdump: thread 1: start. cur_cpu=1
mgdump: thread 2: start. cur_cpu=1
mgdump: thread 3: start. cur_cpu=1
mgdump: thread 4: start. cur_cpu=1
mgdump: thread 5: start. cur_cpu=1
mgdump: thread 6: start. cur_cpu=1
mgdump: thread 7: start. cur_cpu=1
0:0     1:0     2:0     3:0     4:0     5:0     6:0     7:0     sum:0   pps:0
0:0     1:0     2:0     3:0     4:0     5:0     6:0     7:0     sum:0   pps:0
0:0     1:1903079    2:1036794 ... 7:1037943   sum:8095376     pps:8095376
0:0     1:5096935    2:2760622 ... 7:2763532   sum:21639702    pps:13544326
0:0     1:8294247    2:4484658 ... 7:4489184   sum:35187253    pps:13547551
0:0     1:11491047   2:6208288 ... 7:6214460   sum:48732632    pps:13545379
0:0     1:14686823   2:7932240 ... 7:7939956   sum:62277671    pps:13545039
0:0     1:17883909   2:9655759 ... 7:9665151   sum:75822457    pps:13544786
```

---

# qdisc-bypass

```c
// rx_handlerの登録
rc = netdev_rx_handler_register(gc->dev, mgc_handle_frame, mgc);

<snip>

// mgc_handle_frame
rx_handler_result_t mgc_handle_frame(struct sk_buff ** pskb)
{
    rx_handler_result_t res = RX_HANDLER_CONSUMED;

    /* 受信パケット処理: CPU毎に用意したring bufにデータを追加*/

    return res;
}
```

---

# read(2)による可変長bulk read

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
  - pthreadを利用して、NIC HWQueue分threadを立ち上げてパケット処理
  - coreとの貼り付けはpthread_setaffinity_npを利用
* Kernel space
  - read(2)は、各cpu coreごとに呼ばれるため、smp_processor_id()で判定
    * `struct rxring *rx = &mgc->rxrings[smp_processor_id()];`

---

# pcapとpcap-ngにおけるナノ秒TStamp対応

* pcap、pcan-ngともにナノ秒タイムスタンプに対応可能
  - pcap: pcap_hdr_s構造体のmagic_numberを変更 (0xa1b2c3d4 -> 0xa1b23c4d)
  - pcapng: if_tsresol=9にし、Enhanched Packet Blockを使用
* 今回はpcapを選択 (pcap-ngのデータデータ構造は処理が大変...)

---

# 受信パフォーマンス計測

* 今回のアプローチは、DPDK/netmapに比べてお手軽だが、性能で劣る
  - kmem_cache (skb_buffのmalloc/kfreeのオーバヘッド)
  - Device driver内はper packet (skb)でパケット処理, など
* 特に垂直方向(single HWQueueあたり)の性能が悪くなる
  - single HWQueue = 同一ホストからのUDP/TCPストリームなど
* そこで、パフォーマンスは以下の2シナリオで計測
  - Single HWQueue
  - Multi HWQueue: 送信側ホストでsource IP addrをインクリメンタルで回す

---

# 受信性能 (Disable HWTstamp)

![](https://raw.githubusercontent.com/sora/slide/master/iij_201611/images/BothHWQueue.png)

---

# まとめ

![](https://raw.githubusercontent.com/sora/slide/master/iij_201611/images/mgdump.png)

{.column}

* ネットワーク計測用のPacketIO実装
* サンプルアプリとしてパケットキャプチャツール
* NIC(もしくはデバイスドライバ)の性能制限があるものの
  - MultiHWQueueでは、パケット長100Byteで10Gbpsを達成
  - SingleHWQueueは今後の課題

---

# HPIO (Hayai Packet IO)

* mgcapからkernel moduleを取り出して汎用化したもの (with upa)
* 対応(予定)機能
  - 汎用パケットIO化 (snaplenを取り除く)
  - 送信機能 (writev with O_NONBLOCK?)
  - read/write --> readv/writev
  - myringbuf --> linux/ptr_ring.h
  - 仮想デバイス
* アプリケーション
  - Bridge/Forwarding
  - pktgen
  - Metric monitoring

---
