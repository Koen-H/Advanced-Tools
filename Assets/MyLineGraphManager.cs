using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class MyLineGraphManager : MonoBehaviour
{
    [SerializeField] LineGraphManager lineGraphManager;

    [SerializeField] List<TextMesh> yPoints;


    public void LoadData(List<float> fpsData)
    {

        int index = fpsData.Count;
        float highestValue = 0;
        for (int i = 0; i < index; i++)
        {
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
