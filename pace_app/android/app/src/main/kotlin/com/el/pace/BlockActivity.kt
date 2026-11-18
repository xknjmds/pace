package com.el.pace

import android.app.Activity
import android.content.Intent
import android.os.Bundle
import android.widget.Button
import android.widget.TextView
import java.text.DateFormat
import java.util.Date

/**
 * The calm screen shown over a blocked app. The emergency unlock is always
 * here and always works (CLAUDE.md rule 11). Back goes home, never back
 * into the blocked app.
 */
class BlockActivity : Activity() {
  override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)
    setContentView(R.layout.gate_block)
    bind(intent)
  }

  override fun onNewIntent(intent: Intent) {
    super.onNewIntent(intent)
    setIntent(intent)
    bind(intent)
  }

  private fun bind(intent: Intent) {
    val store = GateStore(this)
    val reason = intent.getStringExtra(EXTRA_REASON) ?: "morning"
    val until = intent.getLongExtra(EXTRA_UNTIL, 0L)
    val time = DateFormat.getTimeInstance(DateFormat.SHORT).format(Date(until))
    findViewById<TextView>(R.id.gate_title).text =
        if (reason == "windDown") getString(R.string.gate_title_evening)
        else getString(R.string.gate_title_morning)
    findViewById<TextView>(R.id.gate_body).text =
        if (reason == "windDown") getString(R.string.gate_body_evening, time)
        else getString(R.string.gate_body_morning, time)
    findViewById<Button>(R.id.gate_unlock).apply {
      text = getString(R.string.gate_unlock, store.unlockMinutes)
      setOnClickListener {
        store.unlockFor(store.unlockMinutes)
        finish()
      }
    }
    findViewById<Button>(R.id.gate_open_pace).setOnClickListener {
      startActivity(
          Intent(this, MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
      finish()
    }
    findViewById<Button>(R.id.gate_home).setOnClickListener { goHome() }
  }

  @Deprecated("Back goes home rather than into the blocked app")
  override fun onBackPressed() {
    goHome()
  }

  private fun goHome() {
    startActivity(
        Intent(Intent.ACTION_MAIN)
            .addCategory(Intent.CATEGORY_HOME)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
    finish()
  }

  companion object {
    const val EXTRA_REASON = "reason"
    const val EXTRA_UNTIL = "until"
  }
}
