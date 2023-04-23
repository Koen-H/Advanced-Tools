using System.Collections;
using System.Collections.Generic;
using Unity.VisualScripting.FullSerializer;
using UnityEngine;
using UnityEngine.UI;

public class MyLineGraphManager : MonoBehaviour
{
    [SerializeField] LineGraphManager lineGraphManager;

    [SerializeField] List<TextMesh> yPoints;
    [SerializeField] List<float> storedFPSData;
    [SerializeField] TextMesh zoomedInText;

    int zoomedIN = 1;

    private void Update()
    {

        if (Input.GetKeyDown(KeyCode.RightArrow)) ZoomGraph(1);
        if (Input.GetKeyDown(KeyCode.LeftArrow)) ZoomGraph(-1);
    }

    void ZoomGraph(int inP) {

        if (storedFPSData == null)
        {
            Debug.Log("There is no data recorded yet!");
            return;
        }
        zoomedIN += inP;
        if (zoomedIN < 0) zoomedIN = 0;
        LoadData(storedFPSData, false);

    }



    public void LoadData(List<float> fpsData, bool newData = true)
    {
        if(newData) storedFPSData = fpsData;
        zoomedInText.text = $"Removed first \n{zoomedIN} iterations";
        lineGraphManager.graphDataPlayer1 = new List<GraphData>();
        lineGraphManager.graphDataPlayer2 = new List<GraphData>();
        int index = fpsData.Count;
        float highestValue = 0;
        for (int i = 0; i < index; i++)
        {
            if (i < zoomedIN) continue;
            GraphData gd = new GraphData();
            gd.marbles = fpsData[i];
            if (gd.marbles > highestValue) highestValue = gd.marbles;
            lineGraphManager.graphDataPlayer1.Add(gd);
            

            GraphData gd2 = new GraphData();
            gd2.marbles = i;
            lineGraphManager.graphDataPlayer2.Add(gd2);
            
        }
        lineGraphManager.highestValue = highestValue;

        int pointValue = (int) (highestValue / yPoints.Count);
        for(int i = 0; i < yPoints.Count; i++)
        {
            yPoints[i].text = $"{(int)(highestValue - (pointValue * i))}";
        }


        this.gameObject.SetActive(true);
        lineGraphManager.ShowGraph();
    }
}
