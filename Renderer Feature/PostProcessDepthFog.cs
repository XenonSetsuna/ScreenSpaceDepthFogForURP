using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class PostProcessDepthFog : ScriptableRendererFeature
{
    [System.Serializable]
    public class DepthFogSettings
    {
        public RenderPassEvent Event = RenderPassEvent.BeforeRenderingPostProcessing;
    }
    public DepthFogSettings settings = new DepthFogSettings();
    class DepthFogPass : ScriptableRenderPass
    {
        // This method is called before executing the render pass.
        // It can be used to configure render targets and their clear state. Also to create temporary render target textures.
        // When empty this render pass will render to the active camera render target.
        // You should never call CommandBuffer.SetRenderTarget. Instead call <c>ConfigureTarget</c> and <c>ConfigureClear</c>.
        // The render pipeline will ensure target setup and clearing happens in a performant manner.

        RenderTargetIdentifier cameraID;
        Material depthFogMaterial;
        static readonly int finalID = Shader.PropertyToID("_DepthFogTex");
        static readonly int tempID = Shader.PropertyToID("_TempTex");
        static readonly int colorID = Shader.PropertyToID("_Color");
        static readonly int intensityID = Shader.PropertyToID("_Intensity");
        static readonly int heightID = Shader.PropertyToID("_Height");
        static readonly int distanceID = Shader.PropertyToID("_Distance");
        static readonly int thicknessID = Shader.PropertyToID("_Thickness");
        static readonly int noiseTextureID = Shader.PropertyToID("_NoiseTexture");
        static readonly int noiseOffsetID = Shader.PropertyToID("_NoiseOffset");

        public DepthFogPass(RenderPassEvent evt)
        {
            renderPassEvent = evt;
            Shader shader = Shader.Find("Post-process/DepthFog");
            if (shader == null)
            {
                Debug.LogError("后处理雾效：无法找到shader");
                return;
            }
            depthFogMaterial = CoreUtils.CreateEngineMaterial(shader);
        }

        public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
        {
        }

        // Here you can implement the rendering logic.
        // Use <c>ScriptableRenderContext</c> to issue drawing commands or execute command buffers
        // https://docs.unity3d.com/ScriptReference/Rendering.ScriptableRenderContext.html
        // You don't have to call ScriptableRenderContext.submit, the render pipeline will call it at specific points in the pipeline.
        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            if (!renderingData.cameraData.postProcessEnabled) return;
            DepthFog depthFog = VolumeManager.instance.stack.GetComponent<DepthFog>();
            if (depthFog == null)
            {
                Debug.LogError("未检测到Depth Fog后处理");
                return;
            }
            if (!depthFog.IsActive())
            {
                return;
            }
            CommandBuffer cmd = CommandBufferPool.Get("cmd for post-process depthFog");
            depthFogMaterial.SetColor(colorID, depthFog.color.value);
            depthFogMaterial.SetFloat(intensityID, depthFog.intensity.value);
            depthFogMaterial.SetFloat(heightID, depthFog.height.value);
            depthFogMaterial.SetFloat(distanceID, depthFog.distance.value);
            depthFogMaterial.SetFloat(thicknessID, depthFog.thickness.value);
            depthFogMaterial.SetTexture(noiseTextureID, depthFog.noiseTexture.value);
            depthFogMaterial.SetFloat(noiseOffsetID, depthFog.noiseOffset.value);
            cmd.SetGlobalTexture(finalID, cameraID);
            cmd.GetTemporaryRT(tempID, renderingData.cameraData.camera.scaledPixelWidth, renderingData.cameraData.camera.scaledPixelHeight, 0, FilterMode.Point, RenderTextureFormat.Default);
            cmd.Blit(cameraID, tempID);
            cmd.Blit(tempID, cameraID, depthFogMaterial, 0);
            context.ExecuteCommandBuffer(cmd);
            CommandBufferPool.Release(cmd);
        }

        // Cleanup any allocated resources that were created during the execution of this render pass.
        public override void OnCameraCleanup(CommandBuffer cmd)
        {
        }
        public void Setup(in RenderTargetIdentifier currentTarget)
        {
            this.cameraID = currentTarget;
            this.cameraID = currentTarget;
        }
    }

    DepthFogPass depthFogPass;

    /// <inheritdoc/>
    public override void Create()
    {
        depthFogPass = new DepthFogPass(settings.Event);
    }

    // Here you can inject one or multiple render passes in the renderer.
    // This method is called when setting up the renderer once per-camera.
    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        depthFogPass.Setup(renderer.cameraColorTarget);
        renderer.EnqueuePass(depthFogPass);
    }
}


