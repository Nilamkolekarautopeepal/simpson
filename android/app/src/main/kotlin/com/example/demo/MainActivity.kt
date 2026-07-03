package example.autopeepalApp.com

import android.content.Context
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.*
import java.net.InetAddress

class MainActivity : FlutterActivity() {

    private val CHANNEL = "hotspot/devices"
    private val scope = CoroutineScope(Dispatchers.IO)

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "getConnectedDevices") {
                    scope.launch {
                        val devices = fetchConnectedDevices()
                        withContext(Dispatchers.Main) {
                            result.success(devices)
                        }
                    }
                } else {
                    result.notImplemented()
                }
            }
    }

    private suspend fun fetchConnectedDevices(): List<String> {
        val hotspotIp = getHotspotIp() ?: return emptyList()
        val baseIp = hotspotIp.substringBeforeLast(".") + "."
        val connected = mutableListOf<String>()

        // scan IPs from .2 to .254
        for (i in 2..254) {
            val ip = "$baseIp$i"
            try {
                val addr = InetAddress.getByName(ip)
                if (addr.isReachable(150)) {
                    connected.add(ip)
                }
            } catch (_: Exception) {
                // ignore unreachable
            }
        }
        return connected
    }

    private fun getHotspotIp(): String? {
        return try {
            val wm = applicationContext.getSystemService(Context.WIFI_SERVICE) as android.net.wifi.WifiManager
            val dhcpInfo = wm.dhcpInfo ?: return null
            val ip = dhcpInfo.ipAddress
            if (ip == 0) return null
            String.format(
                "%d.%d.%d.%d",
                ip and 0xff,
                ip shr 8 and 0xff,
                ip shr 16 and 0xff,
                ip shr 24 and 0xff
            )
        } catch (_: Exception) {
            null
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        scope.cancel()
    }
}
