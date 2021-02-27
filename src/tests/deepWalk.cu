#include "testBase.h"

#include <stdlib.h>    

struct RandomWalkApp {
  __host__ __device__ int steps() {return 100;}

  __host__ __device__ 
  int stepSize(int k) {
    return 1;
  }

  __host__ __device__ int samplingType()
  {
    return SamplingType::IndividualNeighborhood;
  }

  __host__ __device__ OutputFormat outputFormat()
  {
    return SampledVertices;
  }

  #define VERTICES_PER_SAMPLE 1

  __host__ __device__ EdgePos_t numSamples(CSR* graph)
  {
    return graph->get_n_vertices() / VERTICES_PER_SAMPLE;
  }

  template<class SampleType>
  __host__ std::vector<VertexID_t> initialSample(int sampleIdx, CSR* graph, SampleType& sample)
  {
    std::vector<VertexID_t> initialValue;

    for (int i = 0; i < VERTICES_PER_SAMPLE; i++) {
      // initialValue.push_back(rand() % graph->get_n_vertices());
      initialValue.push_back(sampleIdx);
    }

    return initialValue;
  }

  __host__ __device__ EdgePos_t initialSampleSize(CSR* graph)
  {
    return VERTICES_PER_SAMPLE;
  }

  __host__ __device__ bool hasExplicitTransits()
  {
    return false;
  }

  template<class SampleType>
  __host__ __device__ VertexID_t stepTransits(int step, const VertexID_t sampleID, SampleType& sample, int transitIdx, curandState* randState)
  {
  }

  template<class SampleType>
  __host__ SampleType initializeSample(CSR* graph, const VertexID_t sampleID)
  {
    SampleType sample;

    return sample;
  }
};

struct DeepWalkApp : public RandomWalkApp {
  template<typename SampleType, typename EdgeArray, typename WeightArray>
  __device__ inline
  VertexID next(int step, CSRPartition* csr, const VertexID* transit, const VertexID sampleIdx,
                SampleType* sample, 
                const float max_weight,
                EdgeArray& transitEdges, WeightArray& transitEdgeWeights,
                const EdgePos_t numEdges, const VertexID_t neighbrID, curandState* state)
  {
    if (numEdges == 1) {
      return transitEdges[0];
    }
    
    EdgePos_t x = RandNumGen::rand_int(state, numEdges);
    float y = curand_uniform(state)*max_weight;

    while (y > transitEdgeWeights[x]) {
      x = RandNumGen::rand_int(state, numEdges);
      y = curand_uniform(state)*max_weight;
    }

    return transitEdges[x];
  }
};

struct PPRApp : public RandomWalkApp {
  template<typename SampleType, typename EdgeArray, typename WeightArray>
  __device__ inline
  VertexID next(int step, CSRPartition* csr, const VertexID* transit, const VertexID sampleIdx,
                SampleType* sample, 
                const float max_weight,
                EdgeArray& transitEdges, WeightArray& transitEdgeWeights,
                const EdgePos_t numEdges, const VertexID_t neighbrID, curandState* state)
  {
    if (numEdges == 1) {
      return transitEdges[0];
    }
    
    EdgePos_t x = RandNumGen::rand_int(state, numEdges);
    float y = curand_uniform(state)*max_weight;

    while (y > transitEdgeWeights[x]) {
      x = RandNumGen::rand_int(state, numEdges);
      y = curand_uniform(state)*max_weight;
    }

    return transitEdges[x];
  }
};

class DummySample
{

};

struct Node2VecApp : public RandomWalkApp {
  template<typename SampleType, typename EdgeArray, typename WeightArray>
  __device__ inline
  VertexID next(int step, CSRPartition* csr, const VertexID* transits, const VertexID sampleIdx,
                SampleType* sample, 
                const float max_weight,
                EdgeArray& transitEdges, WeightArray& transitEdgeWeights,
                const EdgePos_t numEdges, const VertexID_t neighbrID, curandState* state)
  {
    if (numEdges == 1 || step == 0) {
      sample->t = *transits;
      return transitEdges[0];
    }  
    
    const float p = 2.0f;
    const float q = 0.5f;

    do {
      EdgePos_t x = RandNumGen::rand_int(state, numEdges);
      VertexID v = transitEdges[x];
      float y = curand_uniform(state)*max(max(p, 1/q), 1.0f);
      const CSR::Edge* tEdges = csr->get_edges(sample->t);
      EdgePos_t tNumEdges = csr->get_n_edges_for_vertex(sample->t);
      float h;
      if (x == sample->t) {
        h = p;
      } else if (utils::binarySearch(tEdges, v, tNumEdges)) {
        h = 1/q;
      } else {
        h = 1.0f;
      }

      if (y < h) {
        sample->t = *transits;
        return v;
      }
    } while (true);
  }
};

class Node2VecSample {
public:
  VertexID t;
};


#define RUNS 1
#define CHECK_RESULTS false

/**DeepWalk**/
// APP_TEST(DeepWalk, DeepWalkApp, CiteseerTP, GRAPH_PATH"/citeseer-weighted.graph", 10, false, "TransitParallel") 
// APP_TEST(DeepWalk, DeepWalkApp, CiteseerSP, GRAPH_PATH"/citeseer-weighted.graph", 10, false, "SampleParallel") 
// APP_TEST(DeepWalk, DeepWalkApp, MicoTP, GRAPH_PATH"/micro-weighted.graph", 10, false, "TransitParallel")
// APP_TEST(DeepWalk, DeepWalkApp, MicoSP, GRAPH_PATH"/micro-weighted.graph", 10, false, "SampleParallel") 
// APP_TEST(DeepWalk, DeepWalkApp, PpiTP, GRAPH_PATH"/ppi_sampled_matrix", 10, false, "TransitParallel")
// APP_TEST(DeepWalk, DeepWalkApp, PpiSP, GRAPH_PATH"/ppi_sampled_matrix", 10, false, "SampleParallel")
#define COMMA ,
// APP_TEST(DummySample, DeepWalk, DeepWalkApp, RedditTP, GRAPH_PATH"/reddit_sampled_matrix", RUNS, CHECK_RESULTS,  checkSampledVerticesResult<DummySample COMMA DeepWalkApp>, "TransitParallel", false)
//APP_TEST(DummySample, DeepWalk, DeepWalkApp, RedditSP, GRAPH_PATH"/reddit_sampled_matrix", RUNS, CHECK_RESULTS, checkSampledVerticesResult<DummySample COMMA DeepWalkApp>, "SampleParallel", false)
// APP_TEST(DummySample, DeepWalk, DeepWalkApp, RedditLB, GRAPH_PATH"/reddit_sampled_matrix", RUNS, CHECK_RESULTS, checkSampledVerticesResult<DummySample COMMA DeepWalkApp>, "TransitParallel", true)
// APP_TEST_BINARY(DummySample, DeepWalk, DeepWalkApp, LiveJournalTP, "/mnt/homes/abhinav/KnightKing/build/bin/LJ1.data", RUNS, CHECK_RESULTS, checkSampledVerticesResult<DummySample COMMA DeepWalkApp>, "TransitParallel", false)
// APP_TEST_BINARY(DummySample, DeepWalk, DeepWalkApp, LiveJournalLB, "/mnt/homes/abhinav/KnightKing/build/bin/LJ1.data", RUNS, CHECK_RESULTS, checkSampledVerticesResult<DummySample COMMA DeepWalkApp>, "TransitParallel", true)
// APP_TEST_BINARY(DummySample, DeepWalk, DeepWalkApp, LiveJournalSP, "/mnt/homes/abhinav/KnightKing/build/bin/LJ1.data", RUNS, CHECK_RESULTS, checkSampledVerticesResult<DummySample COMMA DeepWalkApp>, "SampleParallel", false)
// APP_TEST_BINARY(DummySample, DeepWalk, DeepWalkApp, OrkutTP, "/mnt/homes/abhinav/KnightKing/build/bin/orkut.data", RUNS, CHECK_RESULTS, checkSampledVerticesResult<DummySample COMMA DeepWalkApp>, "TransitParallel", false)
// APP_TEST_BINARY(DummySample, DeepWalk, DeepWalkApp, OrkutLB, "/mnt/homes/abhinav/KnightKing/build/bin/orkut.data", RUNS, CHECK_RESULTS, checkSampledVerticesResult<DummySample COMMA DeepWalkApp>, "TransitParallel", true)
// APP_TEST_BINARY(DummySample, DeepWalk, DeepWalkApp, OrkutSP, "/mnt/homes/abhinav/KnightKing/build/bin/orkut.data", RUNS, CHECK_RESULTS, checkSampledVerticesResult<DummySample COMMA DeepWalkApp>, "SampleParallel", false)


/**Node2Vec**/

APP_TEST_BINARY(Node2VecSample, Node2Vec, Node2VecApp, LiveJournalTP, "/mnt/homes/abhinav/KnightKing/build/bin/LJ1.data", RUNS, CHECK_RESULTS, nullptr, "TransitParallel", false)
APP_TEST_BINARY(Node2VecSample, Node2Vec, Node2VecApp, LiveJournalLB, "/mnt/homes/abhinav/KnightKing/build/bin/LJ1.data", RUNS, CHECK_RESULTS, nullptr, "TransitParallel", true)
APP_TEST_BINARY(Node2VecSample, Node2Vec, Node2VecApp, LiveJournalSP, "/mnt/homes/abhinav/KnightKing/build/bin/LJ1.data", RUNS, CHECK_RESULTS, nullptr, "SampleParallel", false)