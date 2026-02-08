# Stripe: classes opcionais de push provisioning podem não existir no SDK.
# Evita falha do R8 "Missing classes" no build release.
-dontwarn com.stripe.android.pushProvisioning.**
-dontwarn com.reactnativestripesdk.pushprovisioning.**
