// CPU orthographic albedo bake: retain the highest triangle at each texel.
#include <algorithm>
#include <cmath>
#include <cstdint>
#include <fstream>
#include <limits>
#include <vector>
struct Vertex { float x, y, z, u, v; };
int main(int argc, char **argv) {
    if (argc != 3) return 1;
    std::ifstream in(argv[1], std::ios::binary);
    uint32_t count, index_count, width, height;
    in.read(reinterpret_cast<char *>(&count), 4);
    in.read(reinterpret_cast<char *>(&index_count), 4);
    in.read(reinterpret_cast<char *>(&width), 4);
    in.read(reinterpret_cast<char *>(&height), 4);
    std::vector<Vertex> vertices(count);
    std::vector<uint32_t> indices(index_count);
    std::vector<uint8_t> atlas(width * height * 3);
    in.read(reinterpret_cast<char *>(vertices.data()), count * sizeof(Vertex));
    in.read(reinterpret_cast<char *>(indices.data()), index_count * 4);
    in.read(reinterpret_cast<char *>(atlas.data()), atlas.size());
    if (!in) return 2;
    constexpr int size = 512;
    constexpr float extent = 0.60f;
    std::vector<float> depth(size * size, -std::numeric_limits<float>::infinity());
    std::vector<uint8_t> output(size * size * 4, 0);
    for (size_t i = 0; i + 2 < indices.size(); i += 3) {
        Vertex p[3]; float x[3], z[3];
        for (int j = 0; j < 3; j++) {
            p[j] = vertices.at(indices[i + j]);
            x[j] = (p[j].x + extent) / (2 * extent) * size;
            z[j] = (p[j].z + extent) / (2 * extent) * size;
        }
        float det = (x[1]-x[0])*(z[2]-z[0])-(z[1]-z[0])*(x[2]-x[0]);
        if (std::abs(det) < 1e-8f) continue;
        int left = std::max(0, int(std::floor(std::min({x[0],x[1],x[2]}))));
        int right = std::min(size-1, int(std::ceil(std::max({x[0],x[1],x[2]}))));
        int top = std::max(0, int(std::floor(std::min({z[0],z[1],z[2]}))));
        int bottom = std::min(size-1, int(std::ceil(std::max({z[0],z[1],z[2]}))));
        for (int row = top; row <= bottom; row++) for (int col = left; col <= right; col++) {
            float dx = col + 0.5f - x[0], dz = row + 0.5f - z[0];
            float b = (dx*(z[2]-z[0])-dz*(x[2]-x[0]))/det;
            float c = ((x[1]-x[0])*dz-(z[1]-z[0])*dx)/det;
            float a = 1-b-c;
            if (std::min({a,b,c}) < -1e-5f) continue;
            float y = a*p[0].y+b*p[1].y+c*p[2].y;
            int pixel = row*size+col;
            if (y <= depth[pixel]) continue;
            depth[pixel] = y;
            float u = a*p[0].u+b*p[1].u+c*p[2].u;
            float v = a*p[0].v+b*p[1].v+c*p[2].v;
            int tx = std::clamp(int(u*width), 0, int(width)-1);
            // glTF UV v=0 addresses the top row of the embedded image.
            int ty = std::clamp(int(v*height), 0, int(height)-1);
            for (int channel=0; channel<3; channel++)
                output[pixel*4+channel] = atlas[(ty*width+tx)*3+channel];
            output[pixel*4+3] = 255;
        }
    }
    std::ofstream out(argv[2], std::ios::binary);
    out.write(reinterpret_cast<char *>(output.data()), output.size());
    return out ? 0 : 3;
}
