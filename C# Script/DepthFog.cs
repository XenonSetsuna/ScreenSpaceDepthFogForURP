using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class DepthFog : VolumeComponent, IPostProcessComponent
{
    public ColorParameter color = new ColorParameter(Color.white, true, false, true);
    public ClampedFloatParameter intensity = new ClampedFloatParameter(1.0f, 0.0f, 2.0f);
    public FloatParameter height = new FloatParameter(10.0f);
    public ClampedFloatParameter distance = new ClampedFloatParameter(0.0f, 0.0f, 1.0f);
    public ClampedFloatParameter thickness = new ClampedFloatParameter(1.0f, 0.5f, 10.0f);
    public TextureParameter noiseTexture = new TextureParameter(null);
    public FloatParameter noiseOffset = new FloatParameter(0.0f);
    public bool IsActive() => intensity.value > 0;
    public bool IsTileCompatible() => false;
}
