using UnityEngine;
using System.Collections.Generic;

namespace SubnauticaClone
{
    public class ScatterSystem : MonoBehaviour
    {
        [Header("Target Settings")]
        [Tooltip("The object you want to scatter items ON (must have a Collider)")]
        public GameObject targetSurface;
        [Tooltip("The object you want to spawn")]
        public List<GameObject> prefabsToSpawn = new List<GameObject>();

        [Header("Scatter Settings")]
        public int spawnCount = 100;
        public int randomSeed = 42;
        [Tooltip("If true, objects will rotate to match the slope of the surface")]
        public bool alignToNormal = true;

        [Header("Transform Randomization")]
        public float minScale = 0.8f;
        public float maxScale = 1.2f;
        public Vector3 randomRotation = new Vector3(0, 360, 0);

        [Header("Management")]
        public List<GameObject> spawnedObjects = new List<GameObject>();

        public void Scatter()
        {
            if (targetSurface == null || prefabsToSpawn.Count == 0)
            {
                Debug.LogError("Assign a Target Surface and at least one Prefab to the list!");
                return;
            }

            Collider targetCollider = targetSurface.GetComponent<Collider>();
            if (targetCollider == null)
            {
                Debug.LogError("Target Surface must have a Collider (Box, Mesh, or Terrain Collider)!");
                return;
            }

            ClearScattered();

            Random.InitState(randomSeed);

            Bounds bounds = targetCollider.bounds;

            int attempts = 0;
            int maxAttempts = spawnCount * 10;
            int successfulSpawns = 0;

            while (successfulSpawns < spawnCount && attempts < maxAttempts)
            {
                attempts++;


                float randomX = Random.Range(bounds.min.x, bounds.max.x);
                float randomZ = Random.Range(bounds.min.z, bounds.max.z);

                Vector3 rayOrigin = new Vector3(randomX, bounds.max.y + 5f, randomZ);
                Ray ray = new Ray(rayOrigin, Vector3.down);

                RaycastHit hit;
                if (targetCollider.Raycast(ray, out hit, 1000f))
                {
                    SpawnItem(hit);
                    successfulSpawns++;
                }
            }
        }

        void SpawnItem(RaycastHit hit)
        {
            GameObject prefabToSpawn = prefabsToSpawn[Random.Range(0, prefabsToSpawn.Count)];
            GameObject newObj = Instantiate(prefabToSpawn, hit.point, Quaternion.identity); 

            newObj.transform.parent = this.transform;

            if (alignToNormal)
            {
                newObj.transform.up = hit.normal;
            }

            Vector3 rot = new Vector3(
                Random.Range(-randomRotation.x, randomRotation.x),
                Random.Range(-randomRotation.y, randomRotation.y),
                Random.Range(-randomRotation.z, randomRotation.z)
            );
            newObj.transform.Rotate(rot, Space.Self);

            float scale = Random.Range(minScale, maxScale);
            newObj.transform.localScale = Vector3.one * scale;

            spawnedObjects.Add(newObj);
        }

        public void ClearScattered()
        {
            foreach (var obj in spawnedObjects)
            {
                if (obj != null)
                {
                    DestroyImmediate(obj);
                }
            }
            spawnedObjects.Clear();
        }
    }
}