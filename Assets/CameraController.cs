using UnityEngine;

public class CameraController : MonoBehaviour
{
    public float moveSpeed = 10f;
    public float rotationSpeed = 100f;
    private Transform cameraTransform;

    private void Start()
    {
        cameraTransform = transform; 
    }

    void Update()
    {
        // Get the current camera transform

        // Move the camera with WASD keys
        float x = Input.GetAxis("Horizontal") * moveSpeed * Time.deltaTime;
        float z = Input.GetAxis("Vertical") * moveSpeed * Time.deltaTime;
        cameraTransform.Translate(new Vector3(x, 0, z));

        // Rotate the camera with the middle mouse button
        if (Input.GetMouseButton(1))
        {
            float mouseX = Input.GetAxis("Mouse X") * rotationSpeed * Time.deltaTime;
            float mouseY = Input.GetAxis("Mouse Y") * rotationSpeed * Time.deltaTime;
            cameraTransform.RotateAround(cameraTransform.position, Vector3.up, mouseX);
            cameraTransform.RotateAround(cameraTransform.position, -cameraTransform.right, mouseY);
        }
    }
}
