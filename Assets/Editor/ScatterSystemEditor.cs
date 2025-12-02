using UnityEngine;
using UnityEditor;

namespace SubnauticaClone
{
    [CustomEditor(typeof(ScatterSystem))]
    public class ScatterSystemEditor : Editor
    {
        public override void OnInspectorGUI()
        {
            DrawDefaultInspector();

            ScatterSystem script = (ScatterSystem)target;

            GUILayout.Space(20);
            GUILayout.Label("Actions", EditorStyles.boldLabel);

            GUILayout.BeginHorizontal();

            if (GUILayout.Button("Scatter Objects"))
            {
                script.Scatter();
            }

            if (GUILayout.Button("Clear All"))
            {
                script.ClearScattered();
            }

            GUILayout.EndHorizontal();
        }
    }
}