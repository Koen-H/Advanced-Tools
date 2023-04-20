using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Profiling;
public class FpsRecorder : MonoBehaviour
{
    float elapsedTime = 0.0f;
    float fpsSum = 0.0f;
    int frameCount = 0;

    public float averageSecond = 2.0f;
    public int iteration = 0;

    [SerializeField] MyLineGraphManager myLineGraphManager;
    List<float> fpsData = new();

    void Update()
    {
        // Accumulate elapsed time
        elapsedTime += Time.deltaTime;
        frameCount++;

        // If two seconds have elapsed, calculate average fps and reset counters
        if (elapsedTime >= averageSecond)
        {
            float avgFps = fpsSum / frameCount;
            Debug.Log("Average FPS: " + avgFps);

            // Reset counters
            elapsedTime = 0.0f;
            fpsSum = 0.0f;
            frameCount = 0;
            iteration++;
            fpsData.Add(avgFps);
        }
        if (Input.GetKeyDown(KeyCode.P)) myLineGraphManager.LoadData(fpsData);
        // Change a value here (e.g., transform.position)
    }
    public float GetAverageFPS()
    {
        if (frameCount == 0) return 0;
        return fpsSum / frameCount;
    }


    void LateUpdate()
    {
        // Read the current fps and accumulate it
        float fps = 1.0f / Time.unscaledDeltaTime;
        fpsSum += fps;
    }
}
