/*
 * icq2000glue.h
 * Icy Juice
 *
 * Created by Mitz Pettel on Fri Nov 09 2001.
 *
 * Copyright (c) 2001-2003 Mitz Pettel <source@mitzpettel.com>. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. The name of Mitz Pettel may not be used to endorse or promote products
 *    derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
 * OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 * IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
 * NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 *THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 * THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

class icq2000Glue : public sigslot::has_slots<> {
 private:
  ICQConnection	*_owner;
  ICQ2000::Client *targetclient;
  void connected_cb(ICQ2000::ConnectedEvent *c);
  void disconnected_cb(ICQ2000::DisconnectedEvent *c);
  void message_cb(ICQ2000::MessageEvent *c);
  void filetransfer_cb(ICQ2000::FileTransferEvent *fte);
  void messageack_cb(ICQ2000::MessageEvent *c);
//  void filetransferprogress_cb(ICQ2000::FileTransferEvent *fte);
  void logger_cb(ICQ2000::LogEvent *c);
  void socket_cb(ICQ2000::SocketEvent *c);
  void mywant_auto_resp_cb(ICQ2000::ICQMessageEvent *c);
  void self_info_change_cb(ICQ2000::UserInfoChangeEvent* ev);
  void self_status_change_cb(ICQ2000::StatusChangeEvent* ev);
  void contact_status_change_cb(ICQ2000::StatusChangeEvent* ev);
  void search_result_cb(ICQ2000::SearchResultEvent *c);
  void server_based_list_cb(ICQ2000::ContactListEvent *sbe);
  bool isLogging, isLoggingPackets;
  NSDictionary *detailsDictionaryFromContact(ICQ2000::ContactRef c2k);
 public:
  void contact_info_change_cb(ICQ2000::UserInfoChangeEvent* ev);
  icq2000Glue(ICQ2000::Client *theclient, ICQConnection *owner, bool log, bool logPackets);
};
