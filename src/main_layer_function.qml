    /**
     * Get all vector layers - V2 using layerTreeRoot()
     * This is the correct QField API approach
     */
    function getVectorLayersV2() {
        console.log("[Render Sync] ========== GET VECTOR LAYERS V2 ==========")
        displayToast("🔍 Detecting layers...")
        
        var layers = []
        
        try {
            // Check if qgisProject is available
            if (typeof qgisProject === 'undefined' || !qgisProject) {
                console.log("[Render Sync] ERROR: qgisProject not available")
                displayToast("❌ qgisProject not available", "error")
                return []
            }
            
            displayToast("✓ qgisProject exists")
            console.log("[Render Sync] ✓ qgisProject exists")
            
            // Use layerTreeRoot() - this is the correct QField API
            if (typeof qgisProject.layerTreeRoot !== 'function') {
                console.log("[Render Sync] ERROR: layerTreeRoot() not available")
                displayToast("❌ layerTreeRoot() not available", "error")
                return []
            }
            
            displayToast("✓ layerTreeRoot() exists")
            console.log("[Render Sync] ✓ layerTreeRoot() exists")
            
            var root = qgisProject.layerTreeRoot()
            if (!root) {
                console.log("[Render Sync] ERROR: layerTreeRoot() returned null")
                displayToast("❌ layerTreeRoot() returned null", "error")
                return []
            }
            
            displayToast("✓ Got layerTreeRoot")
            console.log("[Render Sync] ✓ Got layerTreeRoot")
            
            // Get children (layer nodes)
            if (typeof root.children !== 'function') {
                console.log("[Render Sync] ERROR: root.children() not available")
                displayToast("❌ root.children() not available", "error")
                return []
            }
            
            var children = root.children()
            console.log("[Render Sync] layerTreeRoot has", children.length, "children")
            displayToast("Found " + children.length + " layer nodes")
            
            // Process each child
            for (var i = 0; i < children.length; i++) {
                var child = children[i]
                console.log("[Render Sync] Processing child", i, ":", child)
                
                try {
                    // Get the layer from the tree node
                    if (typeof child.layer === 'function') {
                        var layer = child.layer()
                        
                        if (layer) {
                            var layerName = layer.name || "Unknown"
                            var layerType = layer.type
                            
                            console.log("[Render Sync] Child", i, "- Layer:", layerName, "Type:", layerType)
                            
                            // Check if it's a vector layer (type === 0)
                            if (layerType === 0) {
                                layers.push(layer)
                                console.log("[Render Sync] ✓ Added vector layer:", layerName)
                                displayToast("✓ Found: " + layerName)
                            } else {
                                console.log("[Render Sync] ✗ Skipping non-vector layer:", layerName, "(type:", layerType, ")")
                            }
                        } else {
                            console.log("[Render Sync] Child", i, "- layer() returned null")
                        }
                    } else if (child.name) {
                        // It might be a group node
                        console.log("[Render Sync] Child", i, "is a group:", child.name)
                    } else {
                        console.log("[Render Sync] Child", i, "- no layer() method")
                    }
                } catch (e) {
                    console.log("[Render Sync] Error processing child", i, ":", e)
                }
            }
            
            // Report results
            if (layers.length > 0) {
                var layerNames = []
                for (var j = 0; j < layers.length; j++) {
                    layerNames.push(layers[j].name || "Unknown")
                }
                console.log("[Render Sync] ✅ SUCCESS - Found", layers.length, "vector layers:", layerNames.join(", "))
                displayToast("✅ Found " + layers.length + " vector layer(s)!", "success")
            } else {
                console.log("[Render Sync] ⚠️ No vector layers found")
                displayToast("⚠️ No vector layers found", "warning")
            }
            
        } catch (e) {
            console.log("[Render Sync] EXCEPTION:", e)
            console.log("[Render Sync] Stack:", e.stack)
            displayToast("❌ ERROR: " + e.toString(), "error")
        }
        
        return layers
    }
