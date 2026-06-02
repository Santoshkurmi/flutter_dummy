package com.mbright.sahakari

import android.os.Build
import android.os.Bundle
import android.view.Surface
import androidx.core.splashscreen.SplashScreen.Companion.installSplashScreen
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.util.Base64
import androidx.annotation.NonNull
import androidx.biometric.BiometricPrompt
import androidx.biometric.BiometricManager
import androidx.core.content.ContextCompat
import androidx.fragment.app.FragmentActivity
import java.security.*
import java.util.concurrent.Executor

class MainActivity: FlutterFragmentActivity() {
    private val CHANNEL = "com.brightbank.app/biometrics"

    override fun onCreate(savedInstanceState: Bundle?) {
        // Enable the native Android Core SplashScreen API
        installSplashScreen()
        
        super.onCreate(savedInstanceState)
        
        // Request the highest refresh rate supported by the display on startup
        setHighRefreshRate()
    }

    private fun setHighRefreshRate() {
        // 1. Handle Modern Android Devices (Android 11 / API 30 and newer)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            try {
                val currentDisplay = this.display
                val modes = currentDisplay?.supportedModes
                
                if (modes != null && modes.isNotEmpty()) {
                    val activeMode = currentDisplay.mode
                    var highestMode = activeMode
                    
                    // Scan hardware profiles matching current layout boundaries
                    for (mode in modes) {
                        if (mode.physicalWidth == activeMode.physicalWidth && mode.physicalHeight == activeMode.physicalHeight) {
                            if (mode.refreshRate > highestMode.refreshRate) {
                                highestMode = mode
                            }
                        }
                    }
                    
                    val layoutParams = window.attributes
                    // Unlocks physical max refresh ceiling
                    layoutParams.preferredDisplayModeId = highestMode.modeId 
                    window.attributes = layoutParams
                    
                    // 2. Prevent modern LTPO panels from aggressively throttling down
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) { // Android 12+
                        try {
                            // Look for the method on the official base class directly
                            val setFrameRateMethod = android.view.Window::class.java.getMethod(
                                "setFrameRate",
                                Float::class.java,
                                Int::class.java,
                                Int::class.java
                            )
                            // Pass 'window', target 120.0f, FIXED_SOURCE (1), and SEAMLESS (0)
                            setFrameRateMethod.invoke(window, 120.0f, 1, 0)
                        } catch (reflectionException: Exception) {
                            // Fallback or ignore safely
                        }
                    }
                }
            } catch (e: Exception) {
                // Safe silent fallback if unusual vendor skins throw exceptions
            }
        } 
        // 3. Handle Legacy Android Profiles (Android 5.1 to 10)
        else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            try {
                val layoutParams = window.attributes
                @Suppress("DEPRECATION")
                layoutParams.preferredRefreshRate = 120.0f
                window.attributes = layoutParams
            } catch (e: Exception) {
                // Fallback
            }
        }
    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Register Refresh Rate MethodChannel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "app.channel.refresh").setMethodCallHandler { call, result ->
            if (call.method == "setHighRefreshRate") {
                setHighRefreshRate()
                result.success(null)
            } else {
                result.notImplemented()
            }
        }

        // Register Biometrics MethodChannel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "createKeyPair" -> {
                    val alias = call.argument<String>("alias") ?: "mb_auth_key"
                    try {
                        val publicKeyPem = createKeyPair(alias)
                        result.success(mapOf("publicKey" to publicKeyPem))
                    } catch (e: Exception) {
                        result.error("KEY_CREATION_FAILED", e.message, null)
                    }
                }
                "sign" -> {
                    val alias = call.argument<String>("alias") ?: "mb_auth_key"
                    val data = call.argument<String>("data")
                    val title = call.argument<String>("title") ?: "Biometric Login"
                    val subtitle = call.argument<String>("subtitle") ?: "Authenticate to sign your login request"
                    if (data == null) {
                        result.error("MISSING_DATA", "Data to sign is missing", null)
                        return@setMethodCallHandler
                    }
                    try {
                        signData(alias, data, title, subtitle, result)
                    } catch (e: Exception) {
                        result.error("SIGNING_ERROR", e.message, null)
                    }
                }
                "authenticate" -> {
                    val title = call.argument<String>("title") ?: "Biometric Verification"
                    val subtitle = call.argument<String>("subtitle") ?: "Verify your identity to continue"
                    authenticateUserOnly(title, subtitle, result)
                }
                "isAvailable" -> {
                    val available = checkBiometricAvailable()
                    result.success(mapOf("isAvailable" to available))
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun createKeyPair(alias: String): String {
        val kpg = KeyPairGenerator.getInstance(
            KeyProperties.KEY_ALGORITHM_RSA,
            "AndroidKeyStore"
        )
        kpg.initialize(
            KeyGenParameterSpec.Builder(
                alias,
                KeyProperties.PURPOSE_SIGN or KeyProperties.PURPOSE_VERIFY
            )
            .setDigests(KeyProperties.DIGEST_SHA256)
            .setSignaturePaddings(KeyProperties.SIGNATURE_PADDING_RSA_PKCS1)
            .setUserAuthenticationRequired(true)
            .setInvalidatedByBiometricEnrollment(true)
            .build()
        )
        val kp = kpg.generateKeyPair()
        val publicKey = kp.public
        val encodedPublicKey = publicKey.encoded
        return "-----BEGIN PUBLIC KEY-----\n" +
                Base64.encodeToString(encodedPublicKey, Base64.DEFAULT) +
                "-----END PUBLIC KEY-----"
    }

    private fun signData(
        alias: String,
        data: String,
        title: String,
        subtitle: String,
        result: MethodChannel.Result
    ) {
        val keyStore = KeyStore.getInstance("AndroidKeyStore")
        keyStore.load(null)
        val privateKey = keyStore.getKey(alias, null) as? PrivateKey
        if (privateKey == null) {
            result.error("KEY_NOT_FOUND", "Key not found. Please setup biometrics first.", null)
            return
        }

        val signature = java.security.Signature.getInstance("SHA256withRSA")
        signature.initSign(privateKey)

        runOnUiThread {
            try {
                val executor = ContextCompat.getMainExecutor(this)
                val promptInfo = BiometricPrompt.PromptInfo.Builder()
                    .setTitle(title)
                    .setSubtitle(subtitle)
                    .setNegativeButtonText("Cancel")
                    .build()

                val biometricPrompt = BiometricPrompt(this as FragmentActivity, executor,
                    object : BiometricPrompt.AuthenticationCallback() {
                        override fun onAuthenticationError(errorCode: Int, errString: CharSequence) {
                            super.onAuthenticationError(errorCode, errString)
                            result.error("AUTH_ERROR", "Authentication error: $errString", null)
                        }

                        override fun onAuthenticationSucceeded(authResult: BiometricPrompt.AuthenticationResult) {
                            super.onAuthenticationSucceeded(authResult)
                            try {
                                val sig = authResult.cryptoObject?.signature
                                if (sig == null) {
                                    result.error("CRYPTO_ERROR", "Signature crypto object is null", null)
                                    return
                                }
                                val decodedData = Base64.decode(data, Base64.DEFAULT)
                                sig.update(decodedData)
                                val signed = sig.sign()
                                val signatureString = Base64.encodeToString(signed, Base64.NO_WRAP)
                                result.success(mapOf("signature" to signatureString))
                            } catch (e: Exception) {
                                result.error("SIGN_FINAL_ERROR", e.message, null)
                            }
                        }

                        override fun onAuthenticationFailed() {
                            super.onAuthenticationFailed()
                        }
                    })

                biometricPrompt.authenticate(promptInfo, BiometricPrompt.CryptoObject(signature))
            } catch (e: Exception) {
                result.error("INTERNAL_PROMPT_ERROR", e.message, null)
            }
        }
    }

    private fun authenticateUserOnly(title: String, subtitle: String, result: MethodChannel.Result) {
        runOnUiThread {
            try {
                val executor = ContextCompat.getMainExecutor(this)
                val promptInfo = BiometricPrompt.PromptInfo.Builder()
                    .setTitle(title)
                    .setSubtitle(subtitle)
                    .setNegativeButtonText("Cancel")
                    .build()

                val biometricPrompt = BiometricPrompt(this as FragmentActivity, executor,
                    object : BiometricPrompt.AuthenticationCallback() {
                        override fun onAuthenticationError(errorCode: Int, errString: CharSequence) {
                            super.onAuthenticationError(errorCode, errString)
                            result.error("AUTH_CANCELLED", "Authentication cancelled: $errString", null)
                        }

                        override fun onAuthenticationSucceeded(authResult: BiometricPrompt.AuthenticationResult) {
                            super.onAuthenticationSucceeded(authResult)
                            result.success(mapOf("verified" to true))
                        }

                        override fun onAuthenticationFailed() {
                            super.onAuthenticationFailed()
                        }
                    })

                biometricPrompt.authenticate(promptInfo)
            } catch (e: Exception) {
                result.error("INTERNAL_AUTH_ERROR", e.message, null)
            }
        }
    }

    private fun checkBiometricAvailable(): Boolean {
        val biometricManager = BiometricManager.from(this)
        val result = biometricManager.canAuthenticate(BiometricManager.Authenticators.BIOMETRIC_STRONG)
        return result == BiometricManager.BIOMETRIC_SUCCESS
    }
}
