using System.Collections.Generic;
using System.Runtime.CompilerServices;
using UnityEngine;
using UnityEngine.Profiling;
public class FpsRecorder : MonoBehaviour
{
    [SerializeField] private RaymarchCamera raymarchSettings;
    [Header("Itteration Manager")]
    [SerializeField]
    [Tooltip("How many iterations?")]
    int iterations = 1;
    [SerializeField] bool increaseModInterval = false;
    [SerializeField]
    [Tooltip("By how much should the raymarchIteration increase?")]
    int iterationStepIncrement = 1;

    [SerializeField]
    [Tooltip("How long should one iteration take? and an average of fps be based of?")]
    public float iterationTime = 1.0f;

    [Header("Itteration Manager")]
    bool isRecording = false;
    [HideInInspector]public int currentIteration = 1;


    float elapsedTime = 0.0f;
    float fpsSum = 0.0f;
    int frameCount = 0;


    [Header("Graph settings")]
    [SerializeField] string graphTitle;
    [SerializeField] MyLineGraphManager myLineGraphManager;
    [SerializeField] TextMesh iterationText;
    [SerializeField] TextMesh dataInput;
    [SerializeField] TextMesh titelMesh;
    [SerializeField]
    List<float> fpsData = new();


    void Update()
    {
        if (isRecording) Record();
       // if (Input.GetKeyDown(KeyCode.P)) myLineGraphManager.LoadData(fpsData);
        if(Input.GetKeyDown(KeyCode.Space)) StartRecording();
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


    void StartRecording()
    {
        if (isRecording) return;
        Debug.Log("Started recording...");
        isRecording = true;
        SetIterationData();
    }

    void SetIterationData()
    {
        int newVal = currentIteration * iterationStepIncrement;
        if (increaseModInterval) raymarchSettings._modInterval = new Vector4(newVal, newVal, newVal, raymarchSettings._modInterval.w);
        else raymarchSettings._MaxIterations = newVal;

    }


    void Record()
    {
        // Accumulate elapsed time
        elapsedTime += Time.deltaTime;
        frameCount++;

        // If two seconds have elapsed, calculate average fps and reset counters
        if (elapsedTime >= iterationTime)
        {
            float avgFps = fpsSum / frameCount;
            //Debug.Log("Average FPS: " + avgFps);

            // Reset counters
            elapsedTime = 0.0f;
            fpsSum = 0.0f;
            frameCount = 0;
            currentIteration++;
            fpsData.Add(avgFps);
            SetIterationData();
        }
        if(currentIteration == iterations)
        {
            isRecording = false;
            Debug.Log("Recording ended!");
            titelMesh.text = graphTitle;
            myLineGraphManager.LoadData(fpsData);        
            iterationText.text = $"Iterations (Increments of {iterationStepIncrement}) avg of {iterationTime} seconds";
            string dataString = $"Max Distance {raymarchSettings._maxDistance}\n Accuracy {raymarchSettings._Accuracy}\n";
            if (raymarchSettings._useLight) dataString += $"Using Light ({raymarchSettings._LightIntensity})\n";
            if (raymarchSettings._useShadow) dataString += $"Using Shadown ({raymarchSettings._ShadowIntensity},{raymarchSettings._ShadowPenumbra})\n";
            if (raymarchSettings._useAmbientOcclusion) dataString += $"Using Ambient Occ ({raymarchSettings._AoStepsize},{raymarchSettings._AoIterations},{raymarchSettings._AoIntensity})\n";
            dataInput.text = dataString;
        }
    }
}
