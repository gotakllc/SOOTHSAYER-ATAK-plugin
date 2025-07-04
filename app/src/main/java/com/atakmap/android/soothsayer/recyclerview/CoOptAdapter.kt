package com.atakmap.android.soothsayer.recyclerview

import android.content.Context
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.*
import androidx.recyclerview.widget.RecyclerView
import com.atakmap.android.gui.PluginSpinner
import com.atakmap.android.maps.MapItem
import com.atakmap.android.maps.Marker
import com.atakmap.android.soothsayer.models.request.TemplateDataModel
import com.atakmap.android.soothsayer.plugin.R

/**
 * An adapter for the Co-Opt feature that receives a correctly styled adapter
 * for its spinners, reusing the exact same implementation as the main screen.
 */
class CoOptAdapter(
    private val context: Context,
    private val markers: List<MapItem>,
    private val templateItems: List<TemplateDataModel>,
    private val getTemplateAdapter: () -> ArrayAdapter<TemplateDataModel>
) : RecyclerView.Adapter<CoOptAdapter.CoOptViewHolder>() {

    // This map holds the final configuration for each callsign, ready to be retrieved.
    val coOptConfigurations = mutableMapOf<String, CoOptConfiguration>()

    /**
     * This comment describes the purpose of the CoOptViewHolder inner class.
     * This ViewHolder holds the view components for a single row in the RecyclerView.
     */
    class CoOptViewHolder(view: View) : RecyclerView.ViewHolder(view) {
        val checkBox: CheckBox = view.findViewById(R.id.co_opt_item_checkbox)
        val callsignTextView: TextView = view.findViewById(R.id.co_opt_item_callsign)
        val templateSpinner: PluginSpinner = view.findViewById(R.id.co_opt_item_template_spinner)
    }

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): CoOptViewHolder {
        // This comment explains that this method inflates the layout for each row.
        val inflater = LayoutInflater.from(parent.context)
        val view = inflater.inflate(R.layout.co_opt_list_item, parent, false)
        return CoOptViewHolder(view)
    }

    override fun onBindViewHolder(holder: CoOptViewHolder, position: Int) {
        val marker = markers[position]
        val callsign = (marker as? Marker)?.getMetaString("callsign", "Unknown") ?: "Unknown"
        holder.callsignTextView.text = callsign

        // Create a configuration entry for this marker as soon as it's displayed
        val config = CoOptConfiguration()
        coOptConfigurations[marker.uid] = config

        // We get the correctly styled adapter from the main receiver and set it.
        holder.templateSpinner.adapter = getTemplateAdapter()
        
        // Set listeners to update the configuration when the user interacts with the row
        holder.checkBox.setOnCheckedChangeListener { _, isChecked ->
            config.isEnabled = isChecked
        }

        holder.templateSpinner.onItemSelectedListener = object : AdapterView.OnItemSelectedListener {
            override fun onItemSelected(parent: AdapterView<*>?, view: View?, pos: Int, id: Long) {
                val validTemplates = templateItems.filter { it.template != null }
                if (pos >= 0 && pos < validTemplates.size) {
                    config.template = validTemplates[pos]
                }
            }
            override fun onNothingSelected(parent: AdapterView<*>?) {
                config.template = null
            }
        }
    }

    override fun getItemCount(): Int = markers.size

    // Data class to hold the configuration for a single row
    data class CoOptConfiguration(
        var isEnabled: Boolean = false,
        var template: TemplateDataModel? = null
    )
} 