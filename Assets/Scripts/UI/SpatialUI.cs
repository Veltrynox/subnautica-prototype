using UnityEngine;

public class SpatialUI : MonoBehaviour
{
    [SerializeField] private GameObject pickupUI;

    public GameObject PickupUI { get; private set; }

    private void Awake()
    {
        PickupUI = pickupUI;
    }
}


