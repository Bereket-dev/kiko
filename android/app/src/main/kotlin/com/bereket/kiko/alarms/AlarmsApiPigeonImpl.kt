package com.bereket.kiko.alarms

// ─────────────────────────────────────────────────────────────────────────────
// AlarmsApiPigeonImpl
// ─────────────────────────────────────────────────────────────────────────────
//
// Adapter that bridges the Pigeon-generated AlarmsApi interface to the
// concrete AlarmsApiImpl.
//
// ACTIVATION STEPS
// ────────────────
// 1. Run Pigeon codegen:
//      dart run pigeon --input pigeons/alarms_api.dart
//    This generates:
//      lib/core/pigeon/alarms_api.g.dart         (Dart host-proxy)
//      android/.../pigeon/AlarmsApi.kt           (Kotlin interface + setUp)
//
// 2. In KikoApplication.registerActivityHandlers, un-comment:
//      import com.bereket.kiko.pigeon.AlarmsApi
//      AlarmsApi.setUp(messenger, AlarmsApiPigeonImpl(alarmsApi))
//
// Until codegen runs this file compiles standalone and does nothing.
// ─────────────────────────────────────────────────────────────────────────────

//
// GENERATED INTERFACE (reproduced here as reference until codegen runs):
//
// interface AlarmsApi {
//   fun scheduleAlarm(alarm: ScheduledAlarm)
//   fun cancelAlarm(alarmId: String)
//   fun cancelAllAlarms()
// }
//
// data class ScheduledAlarm(
//   val alarmId: String,
//   val triggerAtMs: Long,
//   val routeUri: String,
//   val title: String,
//   val body: String,
// )

/**
 * Bridges the Pigeon [AlarmsApi] interface (generated) to [AlarmsApiImpl].
 *
 * Un-comment the class body and the `implements AlarmsApi` clause once Pigeon
 * codegen has been run and the generated AlarmsApi interface is on the
 * classpath.
 */
class AlarmsApiPigeonImpl(
    private val impl: AlarmsApiImpl,
) /* : com.bereket.kiko.pigeon.AlarmsApi */ {

    // ── AlarmsApi interface ────────────────────────────────────────────────

    // Un-comment after running:  dart run pigeon --input pigeons/alarms_api.dart
    //
    // override fun scheduleAlarm(alarm: com.bereket.kiko.pigeon.ScheduledAlarm) {
    //     impl.scheduleAlarm(
    //         alarmId     = alarm.alarmId,
    //         triggerAtMs = alarm.triggerAtMs,
    //         routeUri    = alarm.routeUri,
    //         title       = alarm.title,
    //         body        = alarm.body,
    //         isCallPlan  = false,   // ScheduledAlarm doesn't carry isCallPlan;
    //                                // AlarmReceiver detects this via routeUri prefix
    //     )
    // }
    //
    // override fun cancelAlarm(alarmId: String) {
    //     impl.cancelAlarm(alarmId)
    // }
    //
    // override fun cancelAllAlarms() {
    //     impl.cancelAllAlarms()
    // }
}
