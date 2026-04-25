package com.yshs.sync_clipboard_flutter;

interface IClipboardUserService {
    String getPrimaryClipText() = 1;
    boolean hasPrimaryClipText() = 2;
    void init(IBinder callerToken) = 5;
    void destroy() = 16777114;
}
