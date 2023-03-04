using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;
using System.Collections.Generic;
using UnityEngine.Experimental.Rendering.Universal;
using static UnityEngine.Experimental.Rendering.Universal.RenderObjects;

[ExcludeFromPreset]
[Tooltip("Render Objects simplifies the injection of addtional rebder oasses by exposung a selection of commonly used settings.")]
public class villiInstance : ScriptableRendererFeature
{

    [System.Serializable]
    public class RenderObjectsSettings
    {
        public string passTag = "RenderObjectsFeatures";
        public RenderPassEvent Event = RenderPassEvent.AfterRenderingOpaques;

        public FilterSettings filterSettings = new FilterSettings();

        public Material overrideMaterial = null;
        public int overrideMaterialPassIndex = 0;
        //public GameObject renderer;
        //public GameObject villiInstanceSphere;
        public Mesh villiInstanceSphereMesh;

        public bool overrideDepthState = false;
        public CompareFunction depthCompareFunction = CompareFunction.LessEqual;
        public bool enableWrite = true;

        public StencilStateData stencilSettings = new StencilStateData();

        public CustomCameraSettings cameraSettings = new CustomCameraSettings();
    }

    public RenderObjectsSettings renderObjectsSettings = new RenderObjectsSettings();

    villiInstancePass renderObjectsPass;

    public override void Create()
    {

        FilterSettings filterSettings = renderObjectsSettings.filterSettings;
        if (renderObjectsSettings.Event < RenderPassEvent.BeforeRenderingPrePasses)
        {
            renderObjectsSettings.Event = RenderPassEvent.BeforeRenderingPrePasses;
        }

        renderObjectsPass = new villiInstancePass(renderObjectsSettings.passTag, renderObjectsSettings.Event, filterSettings.PassNames,
            filterSettings.RenderQueueType, filterSettings.LayerMask, renderObjectsSettings.cameraSettings);

        renderObjectsPass.overrideMaterial = renderObjectsSettings.overrideMaterial;
        renderObjectsPass.overrideMaterialPassIndex = renderObjectsSettings.overrideMaterialPassIndex;
        //renderObjectsPass.renderer = renderObjectsSettings.renderer.GetComponent<Renderer>();
        //renderObjectsPass.villiInstanceSphere = renderObjectsSettings.villiInstanceSphere;
        renderObjectsPass.villiInstanceSphereMesh = renderObjectsSettings.villiInstanceSphereMesh;

        if (renderObjectsSettings.overrideDepthState)
        {
            renderObjectsPass.SetDetphState(renderObjectsSettings.enableWrite, renderObjectsSettings.depthCompareFunction);
        }
        if (renderObjectsSettings.stencilSettings.overrideStencilState)
        {
            renderObjectsPass.SetStencilState(renderObjectsSettings.stencilSettings.stencilReference, renderObjectsSettings.stencilSettings.stencilCompareFunction,
                renderObjectsSettings.stencilSettings.passOperation, renderObjectsSettings.stencilSettings.failOperation, renderObjectsSettings.stencilSettings.zFailOperation);
        }
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        renderer.EnqueuePass(renderObjectsPass);
    }
}


