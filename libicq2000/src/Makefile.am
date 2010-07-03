##
## Process with automake to produce Makefile.in
##

lib_LTLIBRARIES = libicq2000.la

libicq2000_la_SOURCES = \
 buffer.cpp         ICBMCookie.cpp      SNAC-BUD.h    SocketClient.cpp \
 buffer.h           ICBMCookie.h        SNAC.cpp      SocketClient.h \
 Cache.h            ICQ.cpp             SNAC-GEN.cpp  socket.cpp \
 Capabilities.cpp   ICQ.h               SNAC-GEN.h    socket.h \
 Capabilities.h     MessageHandler.cpp  SNAC.h        sstream_fix.h \
 Client.cpp         MessageHandler.h    SNAC-LOC.cpp  time_extra.cpp \
 Contact.cpp        RequestIDCache.h    SNAC-LOC.h    TLV.cpp \
 ContactList.cpp    SeqNumCache.h       SNAC-MSG.cpp  TLV.h \
 ContactTree.cpp    SMTPClient.cpp      SNAC-MSG.h    Translator.cpp \
 DCCache.h          SMTPClient.h        SNAC-SBL.cpp  UserInfoBlock.cpp \
 DirectClient.cpp   SNAC-base.cpp       SNAC-SBL.h    UserInfoBlock.h \
 DirectClient.h     SNAC-base.h         SNAC-SRV.cpp   \
 events.cpp         SNAC-BOS.cpp        SNAC-SRV.h    version.cpp \
 exceptions.cpp     SNAC-BOS.h          SNAC-UIN.cpp  Xml.cpp \
 ICBMCookieCache.h  SNAC-BUD.cpp        SNAC-UIN.h    Xml.h \
 FileTransferClient.h  FileTransferClient.cpp FTCache.h

libicq2000_la_LDFLAGS = -version-info @LIBICQ2000_SO_VERSION@

