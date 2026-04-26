package com.yshs.sync_clipboard_flutter

import android.content.ClipData
import android.content.ClipDescription
import kotlin.system.exitProcess
import android.os.IBinder

/**
 * 运行在 Shizuku UserService 进程中的剪贴板读取服务。
 */
class ClipboardUserService : IClipboardUserService.Stub() {

    companion object {
        private const val TAG = "ShizukuClipboard.UserService"
        private const val PACKAGE_NAME = "com.android.shell"
        private var clipboardService: Any? = null

        init {
            if (android.os.Process.myUid() == 0) {
                try {
                    android.system.Os.setgid(2000)
                    android.system.Os.setuid(2000)
                    android.util.Log.i(TAG, "Switched UID/GID from root to shell for clipboard access")
                } catch (e: Exception) {
                    android.util.Log.e(TAG, "Failed to switch UID from root to shell", e)
                }
            }
        }

        /**
         * 获取 Android 系统剪贴板 Binder 服务。
         */
        private fun getClipboardService(): Any? {
            if (clipboardService != null) {
                return clipboardService
            }

            return try {
                val serviceManager = Class.forName("android.os.ServiceManager")
                val getService = serviceManager.getMethod("getService", String::class.java)
                val binder = getService.invoke(null, "clipboard") as? IBinder ?: return null
                val clipboardStub = Class.forName("android.content.IClipboard\$Stub")
                val asInterface = clipboardStub.getMethod("asInterface", IBinder::class.java)
                clipboardService = asInterface.invoke(null, binder)
                clipboardService
            } catch (e: Exception) {
                android.util.Log.e(TAG, "Failed to get clipboard service", e)
                null
            }
        }

        /**
         * 查找系统版本对应签名的剪贴板方法并调用。
         */
        private fun findAndInvokeMethod(clipboard: Any, methodName: String): Any? {
            val methods = clipboard.javaClass.methods
                .filter { it.name == methodName }
                .sortedByDescending { it.parameterCount }

            for (method in methods) {
                val params = method.parameterTypes
                val args = buildArgs(params) ?: continue
                for (i in params.indices) {
                    if (params[i] == String::class.java) {
                        args[i] = PACKAGE_NAME
                        break
                    }
                }

                try {
                    return method.invoke(clipboard, *args)
                } catch (e: Exception) {
                    android.util.Log.e(TAG, "Failed to invoke $methodName with ${params.size} params", e)
                }
            }

            android.util.Log.e(TAG, "No suitable method found: $methodName")
            return null
        }

        /**
         * 为不同系统版本的隐藏剪贴板方法构造兼容参数。
         */
        private fun buildArgs(paramTypes: Array<Class<*>>): Array<Any?>? {
            return try {
                paramTypes.map { type ->
                    when {
                        type == String::class.java -> null
                        type == Int::class.javaPrimitiveType || type == Int::class.java -> 0
                        type == Long::class.javaPrimitiveType || type == Long::class.java -> 0L
                        type == Boolean::class.javaPrimitiveType || type == Boolean::class.java -> false
                        else -> return null
                    }
                }.toTypedArray()
            } catch (_: Exception) {
                null
            }
        }
    }

    /**
     * 读取当前主剪贴板的文本内容。
     */
    override fun getPrimaryClipText(): String {
        return try {
            val clipboard = getClipboardService() ?: return ""
            val clip = findAndInvokeMethod(clipboard, "getPrimaryClip") as? ClipData
            clip?.takeIf { it.itemCount > 0 }?.getItemAt(0)?.text?.toString() ?: ""
        } catch (e: Exception) {
            android.util.Log.e(TAG, "getPrimaryClipText failed", e)
            ""
        }
    }

    /**
     * 判断当前主剪贴板是否包含文本内容。
     */
    override fun hasPrimaryClipText(): Boolean {
        return try {
            val clipboard = getClipboardService() ?: return false
            val desc = findAndInvokeMethod(clipboard, "getPrimaryClipDescription") as? ClipDescription
            desc?.hasMimeType("text/*") ?: false
        } catch (e: Exception) {
            android.util.Log.e(TAG, "hasPrimaryClipText failed", e)
            false
        }
    }

    /**
     * 绑定调用进程死亡监听，避免 UserService 泄露。
     */
    override fun init(callerToken: IBinder) {
        try {
            callerToken.linkToDeath({
                android.util.Log.i(TAG, "Caller process died, exiting UserService")
                exitProcess(0)
            }, 0)
        } catch (e: Exception) {
            android.util.Log.e(TAG, "Failed to link caller token death", e)
        }
    }

    /**
     * 销毁 UserService 进程并释放缓存服务。
     */
    override fun destroy() {
        android.util.Log.i(TAG, "UserService destroy called")
        clipboardService = null
        exitProcess(0)
    }
}
