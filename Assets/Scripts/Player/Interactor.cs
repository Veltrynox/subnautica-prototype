using UnityEngine;
using UnityEngine.InputSystem;

/// <summary>
/// Handles player interaction with interactable objects in the game world.
/// </summary>
namespace SubnauticaClone
{
    public class Interactor : MonoBehaviour
    {
        public float interactDistance = 3f;
        private float checkRate = 0.1f;
        private float nextCheckTime;
        private GameObject pickupUI;
        private Transform cam;

        private void Awake()
        {
            cam = Camera.main != null ? Camera.main.transform : null;
            pickupUI = LevelBuilder.Instance.SpatialUI.GetComponent<SpatialUI>().PickupUI;
        }

        void Update()
        {
            if (cam == null) return;

            if (Time.time > nextCheckTime)
            {
                nextCheckTime = Time.time + checkRate;
                Ray ray = new Ray(cam.position, cam.forward);
                if (Physics.Raycast(ray, out RaycastHit hit, interactDistance))
                {
                    IInteractable interactable = hit.collider.GetComponent<IInteractable>();
                    if (interactable != null)
                    {
                        pickupUI.SetActive(true);
                        
                        // Get bounds to center and scale the UI correctly
                        Renderer renderer = hit.collider.GetComponentInChildren<Renderer>();
                        Bounds bounds = renderer != null ? renderer.bounds : hit.collider.bounds;
                        pickupUI.transform.position = bounds.center;
                        pickupUI.transform.localScale = bounds.size * 1.1f;
                    }
                }
                else {
                    pickupUI.SetActive(false);
                }
            }
        }

        private void OnInteract(InputValue value)
        {
            if (value.isPressed)
            {
                Ray ray = new Ray(cam.position, cam.forward);
                if (Physics.Raycast(ray, out RaycastHit hit, interactDistance))
                {
                    IInteractable interactable = hit.collider.GetComponent<IInteractable>();
                    if (interactable != null)
                    {
                        pickupUI.transform.SetParent(null);
                        pickupUI.SetActive(false);
                        interactable.Interact(gameObject);
                    }
                }
            }
        }
    }
}

interface IInteractable
{
    void Interact(GameObject interactor);
}