using UnityEngine;

namespace SubnauticaClone
{
    public class CollectableSpawner : MonoBehaviour
    {
        public GameObject berryPrefab;
        public Transform spawnPoint;
        public float respawnTime = 20f;

        private GameObject currentBerry;
        private float timer = 0f;

        void Start()
        {
            SpawnBerry();
        }

        void Update()
        {
            if (currentBerry == null)
            {
                timer += Time.deltaTime;
                if (timer >= respawnTime)
                {
                    SpawnBerry();
                    timer = 0f;
                }
            }
        }

        void SpawnBerry()
        {
            currentBerry = Instantiate(berryPrefab, spawnPoint.position, spawnPoint.rotation, spawnPoint);
        }
    }
}