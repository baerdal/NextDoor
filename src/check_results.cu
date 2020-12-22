bool check_result(CSR* csr, const VertexID_t INVALID_VERTEX, std::vector<VertexID_t>& initialSamples, 
                  const size_t finalSampleSize, std::vector<VertexID_t>& finalSamples)
{
  //Check result by traversing all sampled neighbors and making
  //sure that if neighbors at kth-hop is an adjacent vertex of one
  //of the k-1th hop neighbors.

  //First create the adjacency matrix.
  std::cout << "checking results" << std::endl;
  std::unordered_map<VertexID, std::unordered_set<VertexID>> adj_matrix;

  for (VertexID v : csr->iterate_vertices()) {
    adj_matrix[v] = std::unordered_set<VertexID> ();
    for (EdgePos_t i = csr->get_start_edge_idx(v); 
         i <= csr->get_end_edge_idx(v); i++) {
      VertexID e = csr->get_edges()[i];
      adj_matrix[v].insert(e);
    }
  }

  //Now check the correctness
  size_t numNeighborsToSampleAtStep = 0;
  for (int step = 0; step < steps(); step++) {
    if (step == 0) {
      for (size_t s = 0; s < finalSamples.size(); s += finalSampleSize) {
        std::unordered_set<VertexID_t> uniqueNeighbors;

        const size_t sampleId = s/finalSampleSize;
        const VertexID_t initialVal = initialSamples[sampleId];
        size_t contentsLength = 0;
        for (size_t v = s + numNeighborsToSampleAtStep; v < s + stepSize(step); v++) {
          VertexID_t transit = finalSamples[v];
          uniqueNeighbors.insert(transit);
          contentsLength += (int)(transit != INVALID_VERTEX);

          if (transit != INVALID_VERTEX &&
              adj_matrix[initialVal].count(transit) == 0) {
            printf("%s:%d Invalid '%d' in Sample '%ld' at Step '%d'\n", __FILE__, __LINE__, transit, sampleId, step);
            return false;
          }
        }


        // if (uniqueNeighbors.size() < stepSize(step)) {
        //   printf("uniqueneibhors %ld\n", uniqueNeighbors.size());
        // }
        if (contentsLength == 0 && adj_matrix[initialVal].size() > 0) {
          printf("Step %d: '%ld' vertices sampled for sample '%ld' but sum of edges of all vertices in sample is '%ld'\n", 
                  step, contentsLength, sampleId, adj_matrix[initialVal].size());
          return false;
        }
      }
    } else {
      for (size_t s = 0; s < finalSamples.size(); s += finalSampleSize) {
        const size_t sampleId = s/finalSampleSize;
        size_t contentsLength = 0;
        size_t sumEdgesOfNeighborsAtPrevStep = 0;
        const size_t numNeighborsSampledAtPrevStep = (step - 1 == 0) ? 0 : numNeighborsToSampleAtStep/stepSize(step);
        
        for (size_t v = s + numNeighborsSampledAtPrevStep; v < s + numNeighborsToSampleAtStep; v++) {
          sumEdgesOfNeighborsAtPrevStep +=  adj_matrix[finalSamples[v]].size();
        }

        for (size_t v = s + numNeighborsToSampleAtStep; v < s + numNeighborsToSampleAtStep + numNeighborsToSampleAtStep*stepSize(step); v++) {
          VertexID_t transit = finalSamples[v];
          contentsLength += (int)(transit != INVALID_VERTEX);
          
          bool found = false;
          if (transit != INVALID_VERTEX) {
            for (size_t v1 = s + numNeighborsSampledAtPrevStep; v1 < s + numNeighborsToSampleAtStep; v1++) {
              if (adj_matrix[finalSamples[v1]].count(transit) > 0) {
                found = true;
                break;
              }
            }

            if (found == false) {
              printf("%s:%d Invalid '%d' in Sample '%ld' at Step '%d'\n", __FILE__, __LINE__, transit, sampleId, step);
              std::cout << "Contents of samples : [";
              for (size_t v2 = s; v2 < s + finalSampleSize; v2++) {
                std::cout << finalSamples[v2] << ", ";
              }
              std::cout << "]" << std::endl;
              return false;
            }
          }
        }

        if (contentsLength == 0 && sumEdgesOfNeighborsAtPrevStep > 0) {
          printf("Step %d: '%ld' vertices sampled for sample '%ld' but sum of edges of all vertices in sample is '%ld'\n", 
                  step, contentsLength, sampleId, sumEdgesOfNeighborsAtPrevStep);
          return false;
        }
      }
    }

    if (step == 0) numNeighborsToSampleAtStep = stepSize(step);
    else numNeighborsToSampleAtStep *= stepSize(step);
  }

  return true;
}